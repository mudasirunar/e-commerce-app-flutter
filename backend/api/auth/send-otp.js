import { getFirebaseAdmin } from '../../src/firebase.js';
import { sendOtpEmail } from '../../src/brevo.js';
import { generateOtp, hashOtp, generateSecureToken } from '../../src/crypto-utils.js';
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
    const { email, purpose = 'password_reset' } = body;

    if (!email || typeof email !== 'string') {
      return res.status(400).json({ error: 'A valid email address is required.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(normalizedEmail)) {
      return res.status(400).json({ error: 'Invalid email format.' });
    }

    const validPurposes = ['password_reset', 'email_verification'];
    if (!validPurposes.includes(purpose)) {
      return res.status(400).json({ error: 'Invalid purpose. Must be password_reset or email_verification.' });
    }

    const admin = getFirebaseAdmin();
    const db = admin.firestore();

    // For password reset, confirm the user exists in Firebase Auth
    if (purpose === 'password_reset') {
      try {
        await admin.auth().getUserByEmail(normalizedEmail);
      } catch (authErr) {
        if (authErr.code === 'auth/user-not-found') {
          return res.status(404).json({ error: 'No user account found with this email.' });
        }
        console.error('Firebase Auth lookup error:', authErr);
      }
    }

    const challengeKey = `${normalizedEmail}_${purpose}`;
    const challengeRef = db.collection('_otp_challenges').doc(challengeKey);

    // Generate code and secure hash
    const otp = generateOtp();
    const otpHash = hashOtp(otp, normalizedEmail, purpose);
    const challengeId = generateSecureToken();
    const expiryMinutes = 5;
    const expiresAt = Date.now() + (expiryMinutes * 60 * 1000);
    const cooldownMs = 60 * 1000;

    // ATOMIC TRANSACTION: Check cooldown and reserve challenge creation
    // Prevents parallel requests from bypassing cooldown or sending duplicate emails
    await db.runTransaction(async (transaction) => {
      const existingSnap = await transaction.get(challengeRef);

      if (existingSnap.exists) {
        const existingData = existingSnap.data();
        const timeSinceLast = Date.now() - (existingData.createdAt || 0);

        if (timeSinceLast < cooldownMs) {
          const remainingSeconds = Math.ceil((cooldownMs - timeSinceLast) / 1000);
          const cooldownErr = new Error(`Please wait ${remainingSeconds} seconds before requesting another code.`);
          cooldownErr.statusCode = 429;
          throw cooldownErr;
        }
      }

      transaction.set(challengeRef, {
        challengeId,
        email: normalizedEmail,
        purpose,
        otpHash,
        attempts: 0,
        maxAttempts: 5,
        expiresAt,
        createdAt: Date.now(),
        consumed: false
      });
    });

    // Send email via Brevo only after atomic lock is secured
    await sendOtpEmail({
      toEmail: normalizedEmail,
      otp,
      purpose
    });

    return res.status(200).json({
      success: true,
      message: 'Verification code sent to your email.',
      challengeId,
      expiresInMinutes: expiryMinutes
    });

  } catch (error) {
    console.error('Error in send-otp handler:', error);
    return res.status(error.statusCode || 500).json({
      error: error.message || 'Failed to send verification code.'
    });
  }
}
