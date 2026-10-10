import { getFirebaseAdmin } from '../src/firebase.js';

const email = process.argv[2];

if (!email) {
  console.log('Usage: node scripts/set-admin-role.mjs <user-email>');
  console.log('Example: node scripts/set-admin-role.mjs admin@ecommerce.com');
  process.exit(1);
}

async function setAdminRole() {
  try {
    const admin = getFirebaseAdmin();
    console.log(`🔍 Looking up user with email: ${email}...`);

    const user = await admin.auth().getUserByEmail(email);
    console.log(`👤 Found user: ${user.email} (UID: ${user.uid})`);

    // 1. Set Custom Claims in Firebase Auth
    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true,
      role: 'admin'
    });
    console.log('✅ Firebase Auth Custom Claims set: { admin: true, role: "admin" }');

    // 2. Update Firestore user document
    await admin.firestore().collection('users').doc(user.uid).set({
      role: 'admin',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log('✅ Firestore user document updated with role: "admin"');

    console.log('\n🎉 SUCCESS: User is now configured as Store Administrator!');
    console.log('💡 Note: If already signed in on the app, log out and sign back in to refresh the Auth token.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to assign admin role:', error.message);
    process.exit(1);
  }
}

setAdminRole();
