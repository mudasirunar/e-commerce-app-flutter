# Backend placeholder

No backend code, packages, Firebase deployment or email sending has been initialized.
Planned backend: TypeScript Cloud Functions for Firebase with Firebase Admin SDK.
It will own checkout/stock, order cancellation/status changes and Brevo email/OTP security.

Copy `.env.example` to `.env` when configuring local development. A blank `.env` already exists
in this checkout; it is ignored. Never copy server secrets into the Flutter app.
Production secrets belong in a managed secret store; a mobile shared key is not spam protection.
See local `../docs/SETUP.md`, `../docs/SECURITY.md` and `../docs/ARCHITECTURE.md` before implementation.
Docs are excluded locally at user request and must be obtained separately on a fresh clone.
