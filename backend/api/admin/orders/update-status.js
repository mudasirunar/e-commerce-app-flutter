import { getFirebaseAdmin } from '../../../src/firebase.js';
import { authenticateUser, requireAdmin } from '../../../src/auth-middleware.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const user = await authenticateUser(req);
    requireAdmin(user);

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { orderId, newStatus, note } = body;

    const validStatuses = ['Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
    if (!orderId || !newStatus || !validStatuses.includes(newStatus)) {
      return res.status(400).json({
        error: `orderId and valid newStatus (${validStatuses.join(', ')}) are required.`
      });
    }

    const admin = getFirebaseAdmin();
    const db = admin.firestore();
    const orderRef = db.collection('orders').doc(orderId);

    await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(orderRef);
      if (!snap.exists) {
        throw new Error('Order not found.');
      }

      const order = snap.data();
      const currentStatus = order.status;

      if (currentStatus === newStatus) {
        return; // Idempotent no-op
      }

      if (currentStatus === 'Delivered' || currentStatus === 'Cancelled') {
        throw new Error(`Cannot transition from terminal status "${currentStatus}".`);
      }

      // If transitioning to Cancelled, restore stock
      if (newStatus === 'Cancelled') {
        const productSnaps = await Promise.all(
          order.items.map(item => transaction.get(db.collection('products').doc(item.productId)))
        );

        for (let i = 0; i < order.items.length; i++) {
          const item = order.items[i];
          const pSnap = productSnaps[i];
          if (pSnap.exists) {
            const currentStock = pSnap.data().stockQuantity || 0;
            transaction.update(pSnap.ref, {
              stockQuantity: currentStock + item.quantity,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      const statusHistory = Array.isArray(order.statusHistory) ? order.statusHistory : [];
      statusHistory.push({
        status: newStatus,
        previousStatus: currentStatus,
        timestamp: new Date().toISOString(),
        note: note || `Updated by admin (${user.email || user.uid})`,
        by: user.uid
      });

      transaction.update(orderRef, {
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        statusHistory
      });
    });

    return res.status(200).json({
      success: true,
      message: `Order status updated to ${newStatus}.`
    });

  } catch (error) {
    console.error('Admin update status error:', error);
    return res.status(error.statusCode || 400).json({
      error: error.message || 'Failed to update order status.'
    });
  }
}
