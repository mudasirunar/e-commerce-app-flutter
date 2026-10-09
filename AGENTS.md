# Project working instructions

Read this file and `docs/AGENTS.md` before any project work. Read the requirement PDF,
PRD, architecture, design, and task tracker before implementing a feature.

Current authorized scope: initialization and planning only. Do not implement project
features or configure/deploy external services until the user requests the next phase.

The user authorized initial Git initialization, remote connection, commit and push only.
After this initial delivery, do not execute ANY Git command without new explicit user
permission, including read-only commands. Never assume ongoing Git authorization.

Use Android and iOS only. App label: `e commerce app`. Dart package: `ecommerceapp`.
Android application ID and iOS Runner bundle ID: `com.mudasir.ecommerceapp`.

Keep business/data logic separate from UI. Use Provider as required by the assignment.
No speculative dependencies, elaborate abstractions, generated feature code or real payments.
Follow the subtle, minimal UI direction in `docs/DESIGN.md`.

Update `docs/TASK_TRACKER.md` as work proceeds and record actual validation evidence.
Write meaningful tests for security, stock, checkout retries and other important logic.

Never store Brevo credentials, private keys or backend authentication secrets in Flutter.
Backend local secrets belong in ignored `backend/.env`; deployment secrets use a secret manager.
Never print secrets or commit `.env`, service accounts or signing credentials.

The user's latest instruction overrides their earlier docs-tracking preference:
`docs/` is excluded locally via `.git/info/exclude`, never via `.gitignore`.
The root README and this file are tracked to preserve the project entry points.
If local docs are missing on a fresh clone, request the planning documents before feature work.
Do not silently reconstruct requirements or change the local docs policy.
