import { getFirebaseAdmin } from '../../src/firebase.js';
import { authenticateUser, verifyAppCheck } from '../../src/auth-middleware.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    // 1. Verify App Check if configured/provided
    await verifyAppCheck(req);

    const user = await authenticateUser(req);
    const uid = user.uid;
    const isAdmin = !!(user.admin || user.role === 'admin');

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { orderId, reason } = body;

    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required.' });
    }

    const admin = getFirebaseAdmin();
    const db = admin.firestore();
    const orderRef = db.collection('orders').doc(orderId);

    await db.runTransaction(async (transaction) => {
      const orderSnap = await transaction.get(orderRef);

      if (!orderSnap.exists) {
        throw new Error('Order not found.');
      }

      const order = orderSnap.data();

      // Check ownership
      if (order.userId !== uid && !isAdmin) {
        const error = new Error('Forbidden: You can only cancel your own orders.');
        error.statusCode = 403;
        throw error;
      }

      // Check cancellable state
      if (order.status === 'Cancelled') {
        throw new Error('Order is already cancelled.');
      }

      if (!isAdmin && order.status !== 'Pending') {
        throw new Error(`Cannot cancel order in "${order.status}" status. Only Pending orders can be cancelled by customers.`);
      }

      if (['Shipped', 'Delivered'].includes(order.status)) {
        throw new Error(`Cannot cancel an order that has already been ${order.status.toLowerCase()}.`);
      }

      // Restore stock for all order items atomically (eliminates redundant product read phase)
      for (const item of order.items) {
        if (item && item.productId) {
          transaction.update(db.collection('products').doc(item.productId), {
            stockQuantity: admin.firestore.FieldValue.increment(item.quantity),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
      }

      // Update order status to Cancelled
      const statusHistory = Array.isArray(order.statusHistory) ? order.statusHistory : [];
      statusHistory.push({
        status: 'Cancelled',
        timestamp: new Date().toISOString(),
        note: reason || (isAdmin ? 'Cancelled by admin' : 'Cancelled by customer'),
        by: uid
      });

      transaction.update(orderRef, {
        status: 'Cancelled',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledBy: uid,
        cancelReason: reason || null,
        statusHistory
      });
    });

    return res.status(200).json({
      success: true,
      message: 'Order cancelled successfully and inventory restored.'
    });

  } catch (error) {
    console.error('Order cancellation error:', error);
    return res.status(error.statusCode || 400).json({
      error: error.message || 'Failed to cancel order.'
    });
  }
}
