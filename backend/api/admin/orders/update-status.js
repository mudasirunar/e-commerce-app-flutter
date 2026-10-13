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
    const matchedStatus = validStatuses.find(
      s => s.toLowerCase() === String(newStatus || '').trim().toLowerCase()
    );

    if (!orderId || !matchedStatus) {
      return res.status(400).json({
        error: `orderId and valid newStatus (${validStatuses.join(', ')}) are required.`
      });
    }

    const normalizedNewStatus = matchedStatus;

    const admin = getFirebaseAdmin();
    const db = admin.firestore();
    const orderRef = db.collection('orders').doc(orderId);

    await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(orderRef);
      if (!snap.exists) {
        throw new Error('Order not found.');
      }

      const order = snap.data();
      const rawCurrentStatus = order.status || 'Pending';
      const normalizedCurrentStatus = validStatuses.find(
        s => s.toLowerCase() === String(rawCurrentStatus).trim().toLowerCase()
      ) || rawCurrentStatus;

      if (normalizedCurrentStatus === normalizedNewStatus) {
        return; // Idempotent no-op
      }

      // Explicit status transition state machine from ARCHITECTURE.md
      const ALLOWED_TRANSITIONS = {
        Pending: ['Confirmed', 'Processing', 'Cancelled'],
        Confirmed: ['Processing', 'Cancelled'],
        Processing: ['Shipped', 'Cancelled'],
        Shipped: ['Delivered'],
        Delivered: [],
        Cancelled: []
      };

      const allowed = ALLOWED_TRANSITIONS[normalizedCurrentStatus] || [];
      if (!allowed.includes(normalizedNewStatus)) {
        const errorMsg = allowed.length > 0
          ? `Invalid status transition from "${normalizedCurrentStatus}" to "${normalizedNewStatus}". Allowed transitions: ${allowed.join(', ')}.`
          : `Status "${normalizedCurrentStatus}" is terminal and cannot be transitioned to any other status.`;
        const transErr = new Error(errorMsg);
        transErr.statusCode = 400;
        throw transErr;
      }

      // If transitioning to Cancelled, restore stock atomically
      if (normalizedNewStatus === 'Cancelled') {
        for (const item of (order.items || [])) {
          if (item.productId && item.quantity) {
            const pRef = db.collection('products').doc(item.productId);
            transaction.update(pRef, {
              stockQuantity: admin.firestore.FieldValue.increment(item.quantity),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
        }
      }

      const statusHistory = Array.isArray(order.statusHistory) ? order.statusHistory : [];
      statusHistory.push({
        status: normalizedNewStatus,
        previousStatus: normalizedCurrentStatus,
        timestamp: new Date().toISOString(),
        note: note || `Updated by admin (${user.email || user.uid})`,
        by: user.uid
      });

      transaction.update(orderRef, {
        status: normalizedNewStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        statusHistory
      });
    });

    return res.status(200).json({
      success: true,
      message: `Order status updated to ${normalizedNewStatus}.`
    });

  } catch (error) {
    console.error('Admin update status error:', error);
    return res.status(error.statusCode || 400).json({
      error: error.message || 'Failed to update order status.'
    });
  }
}
