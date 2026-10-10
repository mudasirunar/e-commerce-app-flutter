import { getFirebaseAdmin } from '../../src/firebase.js';
import { authenticateUser, verifyAppCheck } from '../../src/auth-middleware.js';
import { generateSecureToken } from '../../src/crypto-utils.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    // 1. Verify App Check (if enabled/provided)
    await verifyAppCheck(req);

    // 2. Authenticate customer
    const user = await authenticateUser(req);
    const uid = user.uid;

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { attemptId, items, deliveryName, deliveryPhone, deliveryAddress } = body;

    // 3. Validate inputs
    if (!attemptId || typeof attemptId !== 'string' || !attemptId.trim()) {
      return res.status(400).json({ error: 'attemptId is required for safe idempotency.' });
    }

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Order must include at least one item.' });
    }

    if (!deliveryName || !deliveryPhone || !deliveryAddress) {
      return res.status(400).json({ error: 'deliveryName, deliveryPhone, and deliveryAddress are required.' });
    }

    // 4. Consolidate and validate item entries (combine duplicate productIds cleanly)
    const itemMap = new Map();
    for (const item of items) {
      if (!item || !item.productId || typeof item.productId !== 'string' || !item.productId.trim()) {
        return res.status(400).json({ error: 'Each order item must specify a valid productId.' });
      }
      const qty = parseInt(item.quantity, 10);
      if (isNaN(qty) || qty <= 0) {
        return res.status(400).json({ error: `Invalid quantity for product ${item.productId}. Must be a positive integer.` });
      }
      const pid = item.productId.trim();
      itemMap.set(pid, (itemMap.get(pid) || 0) + qty);
    }

    const consolidatedItems = Array.from(itemMap.entries()).map(([productId, quantity]) => ({
      productId,
      quantity
    }));

    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    const cleanAttemptId = attemptId.trim();
    const attemptRef = db.collection('users').doc(uid).collection('checkoutAttempts').doc(cleanAttemptId);

    // 5. Run atomic checkout in a single Firestore transaction
    const orderId = `ord_${Date.now()}_${generateSecureToken().slice(0, 6)}`;
    const orderRef = db.collection('orders').doc(orderId);

    const transactionResult = await db.runTransaction(async (transaction) => {
      // Step A: ATOMIC IDEMPOTENCY CHECK INSIDE TRANSACTION
      // Prevents simultaneous duplicate checkout requests from double-ordering
      const attemptSnap = await transaction.get(attemptRef);
      if (attemptSnap.exists) {
        const existingOrderId = attemptSnap.data().orderId;
        const existingOrderRef = db.collection('orders').doc(existingOrderId);
        const existingOrderSnap = await transaction.get(existingOrderRef);
        if (existingOrderSnap.exists) {
          return {
            idempotentReplay: true,
            order: existingOrderSnap.data()
          };
        }
      }

      // Step B: Read all product records first (read before write)
      const productRefs = consolidatedItems.map(item => db.collection('products').doc(item.productId));
      const productSnaps = await Promise.all(productRefs.map(ref => transaction.get(ref)));

      let subtotalMinor = 0;
      const itemSnapshots = [];
      const stockUpdates = [];

      for (let i = 0; i < consolidatedItems.length; i++) {
        const item = consolidatedItems[i];
        const snap = productSnaps[i];

        if (!snap.exists) {
          throw new Error(`Product ${item.productId} is not available.`);
        }

        const product = snap.data();

        if (product.isActive === false) {
          throw new Error(`Product "${product.name}" is no longer available.`);
        }

        const currentStock = product.stockQuantity || 0;
        if (currentStock < item.quantity) {
          throw new Error(`Insufficient stock for "${product.name}". Only ${currentStock} remaining.`);
        }

        const priceMinor = parseInt(product.priceMinor, 10);
        if (isNaN(priceMinor) || priceMinor <= 0) {
          throw new Error(`Invalid price record for "${product.name}".`);
        }

        subtotalMinor += priceMinor * item.quantity;

        itemSnapshots.push({
          productId: item.productId,
          nameSnapshot: product.name,
          unitPriceMinorSnapshot: priceMinor,
          quantity: item.quantity,
          imageUrl: product.imageUrl || ''
        });

        stockUpdates.push({
          ref: snap.ref,
          newStock: currentStock - item.quantity
        });
      }

      // Calculate totals in integer paisa (PKR 200 delivery fee; free delivery over PKR 5,000)
      const deliveryFeeMinor = subtotalMinor >= 500000 ? 0 : 20000;
      const totalMinor = subtotalMinor + deliveryFeeMinor;

      // Step C: Write stock decrements
      for (const update of stockUpdates) {
        transaction.update(update.ref, {
          stockQuantity: update.newStock,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      // Step D: Create order document
      const orderData = {
        orderId,
        userId: uid,
        userEmail: user.email || '',
        attemptId: cleanAttemptId,
        items: itemSnapshots,
        subtotalMinor,
        deliveryFeeMinor,
        totalMinor,
        deliveryName: deliveryName.trim(),
        deliveryPhone: deliveryPhone.trim(),
        deliveryAddress: deliveryAddress.trim(),
        status: 'Pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        statusHistory: [
          { status: 'Pending', timestamp: new Date().toISOString(), note: 'Order placed by customer' }
        ]
      };

      transaction.set(orderRef, orderData);

      // Step E: Record idempotency attempt
      transaction.set(attemptRef, {
        orderId,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      return {
        idempotentReplay: false,
        orderId,
        totalMinor,
        subtotalMinor,
        deliveryFeeMinor,
        items: itemSnapshots,
        order: orderData
      };
    });

    if (transactionResult.idempotentReplay) {
      return res.status(200).json({
        success: true,
        idempotentReplay: true,
        message: 'Existing order returned (idempotent replay).',
        order: transactionResult.order
      });
    }

    // 6. Clean up user cart asynchronously (non-blocking)
    try {
      const cartSnap = await db.collection('users').doc(uid).collection('cart').get();
      if (!cartSnap.empty) {
        const batch = db.batch();
        cartSnap.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
      }
    } catch (cartErr) {
      console.warn('Cart cleanup after checkout completed with warning:', cartErr);
    }

    return res.status(200).json({
      success: true,
      message: 'Order placed successfully.',
      orderId: transactionResult.orderId,
      subtotalMinor: transactionResult.subtotalMinor,
      deliveryFeeMinor: transactionResult.deliveryFeeMinor,
      totalMinor: transactionResult.totalMinor
    });

  } catch (error) {
    console.error('Checkout error:', error);
    const statusCode = error.statusCode || (error.message.includes('Insufficient') || error.message.includes('not available') ? 400 : 500);
    return res.status(statusCode).json({
      error: error.message || 'Checkout failed.'
    });
  }
}
