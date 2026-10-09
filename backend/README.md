# Backend placeholder

No backend code, packages, Firebase deployment or email sending has been initialized.
Planned backend: TypeScript Cloud Functions for Firebase with Firebase Admin SDK.
It will own checkout/stock, order cancellation/status changes and Brevo email/OTP security.

Copy `.env.example` to `.env` when configuring local development. A blank `.env` already exists
in this checkout; it is ignored. Never copy server secrets into the Flutter app.
Production secrets belong in a managed secret store; a mobile shared key is not spam protection.
See local `../docs/SETUP.md`, `../docs/SECURITY.md` and `../docs/ARCHITECTURE.md` before implementation.
Docs are excluded locally at user request and must be obtained separately on a fresh clone.

## Firestore access rules

The root `../firestore.rules` contains the client access policy; paste it into Firebase Console's
Firestore Rules editor. `tests/firestore.rules.test.mjs` supplies emulator security tests.
Rules keep order/catalog writes on the trusted backend; they do not implement backend services.
See local `../docs/FIRESTORE_RULES.md` for claim/field/query requirements.
