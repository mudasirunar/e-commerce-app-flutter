import { getFirebaseAdmin } from '../../src/firebase.js';
import { sendOtpEmail } from '../../src/brevo.js';
import { generateOtp, hashOtp, generateSecureToken } from '../../src/crypto-utils.js';

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  try {
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

    // Cooldown check (60-second cooldown per recipient & purpose)
    const challengeKey = `${normalizedEmail}_${purpose}`;
    const challengeRef = db.collection('_otp_challenges').doc(challengeKey);
    const existingSnap = await challengeRef.get();

    if (existingSnap.exists) {
      const existingData = existingSnap.data();
      const timeSinceLast = Date.now() - (existingData.createdAt || 0);
      const cooldownMs = 60 * 1000;

      if (timeSinceLast < cooldownMs) {
        const remainingSeconds = Math.ceil((cooldownMs - timeSinceLast) / 1000);
        return res.status(429).json({
          error: `Please wait ${remainingSeconds} seconds before requesting another code.`
        });
      }
    }

    // Generate code and secure hash
    const otp = generateOtp();
    const otpHash = hashOtp(otp, normalizedEmail, purpose);
    const challengeId = generateSecureToken();
    const expiryMinutes = 5;
    const expiresAt = Date.now() + (expiryMinutes * 60 * 1000);

    // Save challenge to Firestore (storing only hash, never raw OTP)
    await challengeRef.set({
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

    // Send email via Brevo
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
    return res.status(500).json({
      error: 'Failed to send verification code. Please try again.',
      details: error.message
    });
  }
}
