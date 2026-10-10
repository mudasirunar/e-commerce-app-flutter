import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';

let initialized = false;

export function getFirebaseAdmin() {
  if (initialized && admin.apps.length > 0) {
    return admin;
  }

  // 1. Try Vercel / Cloud environment variables
  if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    let privateKey = process.env.FIREBASE_PRIVATE_KEY;
    // Replace literal '\n' characters if escaped
    privateKey = privateKey.replace(/\\n/g, '\n');
    // Strip surrounding quotes if present
    if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
      privateKey = privateKey.slice(1, -1);
    }

    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID || 'e-commerce-flutter-2a8d1',
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey,
      }),
    });
    initialized = true;
    return admin;
  }

  // 2. Try local service-account.json
  const currentDirKey = path.resolve(process.cwd(), 'service-account.json');
  const backendDirKey = path.resolve(process.cwd(), 'backend', 'service-account.json');
  const moduleRelativeKey = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..', 'service-account.json');
  const envLocalKey = process.env.GOOGLE_APPLICATION_CREDENTIALS
    ? path.resolve(process.cwd(), process.env.GOOGLE_APPLICATION_CREDENTIALS)
    : null;

  const keyPath = (envLocalKey && fs.existsSync(envLocalKey))
    ? envLocalKey
    : (fs.existsSync(backendDirKey)
      ? backendDirKey
      : (fs.existsSync(currentDirKey)
        ? currentDirKey
        : (fs.existsSync(moduleRelativeKey) ? moduleRelativeKey : null)));

  if (keyPath) {
    const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    return admin;
  }

  // 3. Fallback to application default credentials
  admin.initializeApp();
  initialized = true;
  return admin;
}
