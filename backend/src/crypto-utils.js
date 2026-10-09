import crypto from 'crypto';

/**
 * Generates a cryptographically secure 6-digit numeric OTP.
 * @returns {string}
 */
export function generateOtp() {
  const num = crypto.randomInt(100000, 999999);
  return num.toString();
}

/**
 * Computes an HMAC-SHA256 digest of the OTP and challenge parameters.
 * Raw OTPs are NEVER stored in Firestore.
 * 
 * @param {string} code 
 * @param {string} email 
 * @param {string} purpose 
 * @returns {string}
 */
export function hashOtp(code, email, purpose) {
  const secret = process.env.OTP_HMAC_SECRET || 'default-secret-fallback-key-32chars';
  const data = `${code.trim()}:${email.trim().toLowerCase()}:${purpose.trim()}`;
  return crypto.createHmac('sha256', secret).update(data).digest('hex');
}

/**
 * Generates a high-entropy random token for password reset authorization.
 * @returns {string}
 */
export function generateSecureToken() {
  return crypto.randomBytes(32).toString('hex');
}
