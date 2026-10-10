import { getFirebaseAdmin } from '../../src/firebase.js';
import { hashOtp, generateSecureToken } from '../../src/crypto-utils.js';
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
    const computedHash = hashOtp(cleanCode, normalizedEmail, purpose);

    // ATOMIC TRANSACTION: Check attempts, verify hash, and consume challenge atomically
    // Prevents concurrent attempts from bypassing attempt ceiling or double-consuming
    const result = await db.runTransaction(async (transaction) => {
      const snap = await transaction.get(challengeRef);

      if (!snap.exists) {
        const err = new Error('No active verification code found. Please request a new one.');
        err.statusCode = 400;
        throw err;
      }

      const data = snap.data();

      if (data.consumed) {
        const err = new Error('This verification code has already been used.');
        err.statusCode = 400;
        throw err;
      }

      if (Date.now() > data.expiresAt) {
        const err = new Error('Verification code has expired. Please request a new code.');
        err.statusCode = 400;
        throw err;
      }

      const currentAttempts = data.attempts || 0;
      const maxAttempts = data.maxAttempts || 5;

      if (currentAttempts >= maxAttempts) {
        const err = new Error('Maximum attempts reached. Please request a new verification code.');
        err.statusCode = 400;
        throw err;
      }

      // Check hash
      if (computedHash !== data.otpHash) {
        const nextAttempts = currentAttempts + 1;
        transaction.update(challengeRef, { attempts: nextAttempts });
        const attemptsLeft = maxAttempts - nextAttempts;
        return {
          valid: false,
          attemptsLeft,
          locked: attemptsLeft <= 0
        };
      }

      // Code is valid! Mark challenge as consumed atomically
      transaction.update(challengeRef, {
        consumed: true,
        consumedAt: Date.now()
      });

      // If purpose is password_reset, generate and write reset token atomically in the same transaction
      let issuedToken = null;
      if (purpose === 'password_reset') {
        issuedToken = generateSecureToken();
        const tokenRef = db.collection('_password_resets').doc(issuedToken);
        transaction.set(tokenRef, {
          email: normalizedEmail,
          token: issuedToken,
          expiresAt: Date.now() + (15 * 60 * 1000), // 15 minutes
          used: false,
          createdAt: Date.now()
        });
      }

      return {
        valid: true,
        resetToken: issuedToken
      };
    });

    if (!result.valid) {
      return res.status(400).json({
        error: result.locked
          ? 'Maximum attempts reached. Please request a new verification code.'
          : `Invalid code. ${result.attemptsLeft} attempts remaining.`
      });
    }

    const resetToken = result.resetToken;

    // If purpose is email_verification, update Firebase Auth
    if (purpose === 'email_verification') {
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
    return res.status(error.statusCode || 500).json({
      error: error.message || 'Failed to verify code.'
    });
  }
}
