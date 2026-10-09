import { getFirebaseAdmin } from '../../src/firebase.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { email, resetToken, newPassword } = body;

    if (!email || !resetToken || !newPassword) {
      return res.status(400).json({ error: 'Email, resetToken, and newPassword are required.' });
    }

    if (typeof newPassword !== 'string' || newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters long.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    const tokenRef = db.collection('_password_resets').doc(resetToken.trim());
    const snap = await tokenRef.get();

    if (!snap.exists) {
      return res.status(400).json({ error: 'Invalid or expired password reset token.' });
    }

    const tokenData = snap.data();

    if (tokenData.used) {
      return res.status(400).json({ error: 'This reset token has already been used.' });
    }

    if (tokenData.email !== normalizedEmail) {
      return res.status(400).json({ error: 'Token does not match the provided email address.' });
    }

    if (Date.now() > tokenData.expiresAt) {
      return res.status(400).json({ error: 'Password reset token has expired. Please request a new code.' });
    }

    // Lookup user in Firebase Auth and update password
    const user = await admin.auth().getUserByEmail(normalizedEmail);
    await admin.auth().updateUser(user.uid, {
      password: newPassword
    });

    // Invalidate the reset token to prevent reuse
    await tokenRef.update({
      used: true,
      usedAt: Date.now()
    });

    return res.status(200).json({
      success: true,
      message: 'Password has been successfully updated. You can now sign in with your new password.'
    });

  } catch (error) {
    console.error('Error in reset-password handler:', error);
    return res.status(500).json({
      error: 'Failed to reset password. Please try again.',
      details: error.message
    });
  }
}
