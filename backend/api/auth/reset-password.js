import { getFirebaseAdmin } from '../../src/firebase.js';
import { verifyAppCheck } from '../../src/auth-middleware.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    // 1. Verify App Check token if configured/provided
    await verifyAppCheck(req);

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { email, resetToken, newPassword } = body;

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ error: 'Email, resetToken, and newPassword are required.' });
    }

    if (typeof newPassword !== 'string' || newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters long.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const cleanToken = resetToken.trim();
    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    const tokenRef = db.collection('_password_resets').doc(cleanToken);

    // ATOMIC TRANSACTION: Validate and consume token atomically
    // Prevents concurrent requests from reusing or double-consuming the reset token
    await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(tokenRef);

      if (!snap.exists) {
        const err = new Error('Invalid or expired password reset token.');
        err.statusCode = 400;
        throw err;
      }

      const tokenData = snap.data();

      if (tokenData.used) {
        const err = new Error('This reset token has already been used.');
        err.statusCode = 400;
        throw err;
      }

      if (tokenData.email !== normalizedEmail) {
        const err = new Error('Token does not match the provided email address.');
        err.statusCode = 400;
        throw err;
      }

      if (Date.now() > tokenData.expiresAt) {
        const err = new Error('Password reset token has expired. Please request a new code.');
        err.statusCode = 400;
        throw err;
      }

      // Mark token as used atomically inside the transaction
      transaction.update(tokenRef, {
        used: true,
        usedAt: Date.now()
      });
    });

    // Lookup user in Firebase Auth and update password only after atomic consumption succeeds
    const user = await admin.auth().getUserByEmail(normalizedEmail);
    await admin.auth().updateUser(user.uid, {
      password: newPassword
    });

    return res.status(200).json({
      success: true,
      message: 'Password has been successfully updated. You can now sign in with your new password.'
    });

  } catch (error) {
    console.error('Error in reset-password handler:', error);
    return res.status(error.statusCode || 500).json({
      error: error.message || 'Failed to reset password.'
    });
  }
}
