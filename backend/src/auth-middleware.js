import { getFirebaseAdmin } from './firebase.js';

/**
 * Validates the Firebase ID token in the Authorization header.
 * 
 * @param {Object} req - Vercel / Node HTTP request
 * @returns {Promise<Object>} Decoded Firebase user token (uid, email, custom claims)
 */
export async function authenticateUser(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization || '';
  
  if (!authHeader.startsWith('Bearer ')) {
    const error = new Error('Unauthorized: Missing or malformed Authorization header.');
    error.statusCode = 401;
    throw error;
  }

  const token = authHeader.slice(7).trim();
  const admin = getFirebaseAdmin();

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken;
  } catch (err) {
    const error = new Error('Unauthorized: Invalid or expired Firebase ID token.');
    error.statusCode = 401;
    error.details = err.message;
    throw error;
  }
}

/**
 * Ensures caller has admin privileges (either custom claim admin: true or configured admin email).
 * 
 * @param {Object} decodedToken 
 */
export function requireAdmin(decodedToken) {
  if (!decodedToken.admin && decodedToken.role !== 'admin') {
    const error = new Error('Forbidden: Admin access required.');
    error.statusCode = 403;
    throw error;
  }
}
