# e commerce app

Initial Android/iOS Flutter scaffold for ANAS Technologies Task 08.
App label: **e commerce app**. Android/iOS identifier: `com.mudasir.ecommerceapp`.
The app is Flutter's empty Hello World starter; shopping/auth/admin features are not implemented.

## Structure

- `flutter_app/`: Flutter application, Android and iOS only.
- `backend/`: placeholder and environment template for the planned Firebase/Brevo backend.
- `docs/`: local assignment PDF and project plans, excluded through `.git/info/exclude`
  at the user's explicit request. These documents are not included in GitHub clones.
- `AGENTS.md`: working instructions; read before changing the project.

## Run the starter

Install a compatible Flutter SDK and Android/iOS tooling. From `flutter_app/`:

```sh
flutter pub get
flutter run
```

For validation: `flutter analyze`. For a physical iPhone select your own development team
in Xcode; no personal team is committed. The current app has no Firebase/Brevo configuration.
Generated with Flutter's `--empty` template, not the counter demo. No feature tests exist yet.

## Planned services

Firebase email/password Authentication + Firestore + Provider are required by the assignment.
A trusted Firebase Functions backend will handle order integrity and Brevo email/OTP.
No feature dependencies, credentials, database, seed data or deployment were configured.
`backend/.env.example` documents configuration names; local `.env` is ignored and unpopulated.
Server credentials must never be embedded in Flutter.

Read local `docs/PRD.md`, `ARCHITECTURE.md`, `DESIGN.md`, `SETUP.md`, `SECURITY.md`,
`DATA_MODEL.md`, `TEST_PLAN.md` and `TASK_TRACKER.md` before implementing later phases.
Obtain these documents separately if working from a fresh clone.

AI assistance: Codex reviewed the supplied assignment and prepared this scaffold and planning
material. Final submission must update this disclosure and include actual test/build/demo evidence.
After the one-time authorized initial repository setup/push, every Git command requires fresh
explicit user permission.
