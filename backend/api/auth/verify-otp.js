import { getFirebaseAdmin } from '../../src/firebase.js';
import { hashOtp, generateSecureToken } from '../../src/crypto-utils.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const { email, code, purpose = 'password_reset' } = body;

    if (!email || !code) {
      return res.status(400).json({ error: 'Email and verification code are required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const cleanCode = code.toString().trim();

    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    const challengeKey = `${normalizedEmail}_${purpose}`;
    const challengeRef = db.collection('_otp_challenges').doc(challengeKey);
    const snap = await challengeRef.get();

    if (!snap.exists) {
      return res.status(400).json({ error: 'No active verification code found. Please request a new one.' });
    }

    const data = snap.data();

    if (data.consumed) {
      return res.status(400).json({ error: 'This verification code has already been used.' });
    }

    if (Date.now() > data.expiresAt) {
      return res.status(400).json({ error: 'Verification code has expired. Please request a new code.' });
    }

    if (data.attempts >= (data.maxAttempts || 5)) {
      return res.status(400).json({ error: 'Maximum attempts reached. Please request a new verification code.' });
    }

    // Compare hash
    const computedHash = hashOtp(cleanCode, normalizedEmail, purpose);

    if (computedHash !== data.otpHash) {
      await challengeRef.update({
        attempts: (data.attempts || 0) + 1
      });
      const attemptsLeft = (data.maxAttempts || 5) - ((data.attempts || 0) + 1);
      return res.status(400).json({
        error: `Invalid code. ${attemptsLeft > 0 ? `${attemptsLeft} attempts remaining.` : 'Code locked.'}`
      });
    }

    // Code is valid! Mark challenge as consumed
    await challengeRef.update({ consumed: true });

    // Handle purpose-specific success actions
    let resetToken = null;

    if (purpose === 'password_reset') {
      // Issue a scoped 15-minute reset token for resetting password
      resetToken = generateSecureToken();
      const tokenRef = db.collection('_password_resets').doc(resetToken);
      await tokenRef.set({
        email: normalizedEmail,
        token: resetToken,
        expiresAt: Date.now() + (15 * 60 * 1000), // 15 minutes
        used: false,
        createdAt: Date.now()
      });
    } else if (purpose === 'email_verification') {
      // Mark email as verified in Firebase Auth
      try {
        const user = await admin.auth().getUserByEmail(normalizedEmail);
        await admin.auth().updateUser(user.uid, { emailVerified: true });
      } catch (err) {
        console.error('Failed to update emailVerified in Auth:', err);
      }
    }

    return res.status(200).json({
      success: true,
      message: 'Code verified successfully.',
      resetToken
    });

  } catch (error) {
    console.error('Error in verify-otp handler:', error);
    return res.status(500).json({
      error: 'Failed to verify code. Please try again.',
      details: error.message
    });
  }
}
