# e commerce app

Android and iOS e-commerce project for **ANAS Technologies — Flutter Internship, Task 08**. The project specification covers customer shopping, catalog administration, persistent data and secure order handling using Flutter and Firebase, with Brevo for transactional email.

Checkout is a **demo / Cash on Delivery simulation**. No real payment is collected.

| Project identity | Value |
| --- | --- |
| Application and home-screen label | `e commerce app` |
| Dart package | `ecommerceapp` |
| Android application ID / namespace | `com.mudasir.ecommerceapp` |
| iOS application bundle ID | `com.mudasir.ecommerceapp` |
| Platforms | Android, iOS |
| Currency | Pakistani rupee — PKR |
| Repository | [mudasirunar/e-commerce-app-flutter](https://github.com/mudasirunar/e-commerce-app-flutter) |

## Project requirements

These modules define the assignment's product requirements. This README is the product and setup reference; recorded validation results are listed separately below.

| Module | Required behavior |
| --- | --- |
| Authentication | Email/password signup and login, logout, forgot password, validation and session persistence. |
| Home | Featured products, categories and new products with loading, empty and error states. |
| Catalog | Product image, name, PKR price, category and stock availability. |
| Product details | Image, description, price, availability and quantity selection within stock limits. |
| Search and filters | Name search, category and price-range filters, price/newest sorting. |
| Cart | Add/remove products, quantity updates, totals, persistence and unavailable-stock handling. |
| Checkout | Required delivery name/phone/address, authoritative summary, safe submission and confirmed-save feedback. |
| My Orders | Own order list/details, immutable item snapshots, dates, totals, status and Pending-only cancellation. |
| Profile | Basic profile updates and a saved delivery address. |
| Admin | Authorized product create/edit/deactivate, stock updates and order-status management. |

The catalog requirement is **at least 15 sample products across four categories**, with image URLs, descriptions, PKR prices and stock. Admin access must be enforced beyond UI visibility.

## Technology and package roles

Flutter/Dart, Provider, Firebase Authentication and Cloud Firestore are assignment requirements. The architecture specification uses Firebase Functions for trusted operations and backend-only Brevo email delivery.

| Package or service | Responsibility |
| --- | --- |
| `flutter` | Mobile UI and platform integration |
| `flutter_test`, `flutter_lints` | Test tools and static-analysis rules |
| `provider` | View state and user-action coordination |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Email/password identity and sessions |
| `cloud_firestore` | Catalog, profiles, carts and orders |
| `cloud_functions` | Trusted checkout, cancellation, administration and email calls |
| `firebase_app_check` | Attestation for protected backend calls |
| `shared_preferences` | Non-secret checkout-attempt/draft persistence |
| TypeScript, `firebase-functions`, `firebase-admin` | Trusted backend services and transactions |
| Brevo transactional API | Verification/OTP and password-reset email delivery |
| `@firebase/rules-unit-testing` | Emulator access-control validation |

`flutter_app/pubspec.yaml` and `pubspec.lock` are the authoritative installed-dependency records; the table describes integration responsibilities. Firebase Storage is optional because stable product image URLs satisfy the assignment. Never store secrets in shared preferences.

## Repository structure

```text
e-commerce-app-flutter/
├── README.md
├── .gitignore
├── firebase.json               Firebase configuration
├── firestore.rules             Firestore client access policy
├── AGENTS.md                  Local working instructions
├── flutter_app/
│   ├── lib/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   └── pubspec.lock
├── backend/
│   ├── README.md
│   ├── .env.example
│   └── .env                   Local credentials; ignored
└── docs/                      Local assignment and planning documents
```

The tree lists the existing structure. The assignment's modular convention is `models/`, `providers/`, `services/`, `screens/`, `widgets/` and `utils/` under `flutter_app/lib/`.

`docs/` and root `AGENTS.md` are excluded locally through `.git/info/exclude`, as requested by the project owner. They are not excluded through `.gitignore`; obtain local instructions separately when working from a fresh clone. Root `AGENTS.md` was included in the initial commit; its tracking removal is staged locally and is not yet reflected on GitHub.

## Architecture specification

- **Models:** typed product, cart, profile and order data.
- **Providers:** view state and user-action coordination.
- **Services:** Firebase, backend and persistence operations.
- **Screens/widgets:** presentation, navigation, forms and reusable UI.
- **Utilities:** focused validation and formatting helpers.

Flutter uses Firebase Authentication for identity and permitted Firestore operations for catalog reads and own profile/cart data. Trusted backend operations own checkout, stock, cancellation, role-sensitive actions and email delivery. Brevo is contacted from the backend only. Widgets must not perform privileged writes or calculate authoritative checkout totals.

## Local setup and running

Use Flutter stable with **Dart `^3.13.3`**, matching the package constraint. The recorded initialization toolchain is Flutter **3.47.4** and Dart **3.13.3**.

For Android, install Android Studio, the required Android SDK/JDK and an emulator or connect a device. For iOS, use macOS with Xcode and an iOS simulator or connected iPhone. Select your own Apple development team for physical-device signing; no personal team is configured in the repository.

From the repository root:

```sh
cd flutter_app
flutter pub get
flutter devices
flutter run
```

When multiple devices are connected:

```sh
flutter run -d <device-id>
```

## Firebase configuration

1. Create/select the intended Firebase project and choose the Firestore location and Functions region deliberately.
2. Enable **Email/Password** in Firebase Authentication.
3. Register Android and iOS applications with `com.mudasir.ecommerceapp`.
4. Configure Cloud Firestore with least-privilege rules and indexes required by actual queries. Root `firebase.json` points to `firestore.rules` for the access policy.
5. Install the Firebase/FlutterFire CLIs and authenticate with the intended account.
6. Configure Android/iOS, add the required SDK integrations and initialize Firebase before using its services.
7. Configure App Check and verify device attestation before enforcing it for protected calls.

Service-configuration commands:

```sh
firebase login
dart pub global activate flutterfire_cli
```

From `flutter_app/`, replace the placeholder with the actual project ID:

```sh
flutterfire configure --project=<firebase-project-id> --platforms=android,ios
```

Firebase client configuration contains app/project identifiers, not privileged backend credentials. Never put a service-account private key or Brevo key in client configuration or `--dart-define`. Follow the [official Flutter integration guide](https://firebase.google.com/docs/flutter/setup).

Use the Firebase Emulator Suite for isolated Auth, Firestore, Functions and rules checks. Configure device connectivity explicitly; see [Authentication emulator setup](https://firebase.google.com/docs/emulator-suite/connect_auth).

## Backend environment and Brevo setup

Use `backend/.env.example` as the configuration reference and populate `backend/.env` locally. Keep the example free of actual secrets. An environment file alone does not deploy services or integrate them into Flutter.

| Variable | Purpose |
| --- | --- |
| `FIREBASE_PROJECT_ID` | Selected Firebase project |
| `BREVO_API_KEY` | Server-only transactional API credential |
| `BREVO_SENDER_EMAIL` | Verified sender address |
| `BREVO_SENDER_NAME` | `e commerce app` |
| `OTP_HMAC_SECRET` | Independent cryptographic secret for OTP digests |

Verify the Brevo sender/domain, configure required DNS records, enable transactional sending and create a dedicated API key. Keep email HTML/text templates in backend source, with controlled variables, and test delivery using an approved recipient. Brevo-hosted template IDs are not used. Use the backend to call the [Brevo transactional email API](https://developers.brevo.com/docs/send-a-transactional-email).

Use application default credentials for deployed Firebase Admin operations. Store production keys using [Firebase Functions secret configuration](https://firebase.google.com/docs/functions/config-env), bound only to the functions that need them. Keep local secrets, service accounts and signing credentials outside source control.

Firebase remains the password/session authority. The email design uses bound server-generated verification challenges delivered through Brevo. Password recovery uses [Firebase Admin-generated reset action links](https://firebase.google.com/docs/auth/admin/email-action-links) delivered through Brevo, with an approved action handler and redirect.

## Firestore data-model contract

This schema refines the assignment's suggested model. Use server timestamps for audit fields and display dates in the user's local timezone.

| Document path | Fields |
| --- | --- |
| `users/{uid}` | `uid`, `name`, `email`, `phone`, `defaultAddress`, server-owned `role`, `createdAt`, `updatedAt` |
| `categories/{categoryId}` | `categoryId`, `name`, `sortOrder`, `isActive` |
| `products/{productId}` | `productId`, `name`, `normalizedName`, `description`, `categoryId`, `imageUrl`, `priceMinor`, `stockQuantity`, `isActive`, `isFeatured`, `createdAt`, `updatedAt` |
| `users/{uid}/cart/{productId}` | `productId`, `quantity`, `updatedAt` |
| `orders/{orderId}` | `orderId`, `userId`, `attemptId`, `requestFingerprint`, `items`, `subtotalMinor`, `deliveryFeeMinor`, `totalMinor`, delivery fields, `status`, `statusHistory`, `createdAt`, `updatedAt` |
| `users/{uid}/checkoutAttempts/{attemptId}` | `orderId`, `requestFingerprint`, `createdAt` |
| Backend-only email records | Bound challenges, digests, expiry/attempt counters, rate limits and delivery deduplication |

Delivery fields are `deliveryName`, `deliveryPhone` and `deliveryAddress`. An order item contains `productId`, `nameSnapshot`, `unitPriceMinorSnapshot` and `quantity`. Product edits must not rewrite historical order names or prices.

### Monetary representation

Store money as integer **paisa**: 100 paisa equals PKR 1. For example, `125050` represents **PKR 1,250.50**.

```text
line total = unitPriceMinorSnapshot × quantity
subtotalMinor = sum of line totals
totalMinor = subtotalMinor + deliveryFeeMinor
```

Reject non-integer minor-unit input. Convert seed decimal prices with decimal arithmetic and display PKR values to two decimal places. Do not use binary floating-point arithmetic for totals.

## Checkout and order-integrity contract

1. Accept product IDs, positive integer quantities, required delivery fields and a persisted order-attempt ID.
2. Verify caller and payload; read authoritative product prices, active state and stock.
3. Create order snapshots and attempt mapping while deducting stock in one Firestore transaction.
4. Reuse the same attempt ID on retry. Return the existing matching order; reject conflicting payload reuse.
5. Preserve the cart on ambiguous network failure. Confirm only after a confirmed save.
6. Prevent repeated submission in the UI and backend; stock must never become negative.

Do not call email providers inside transactions that can rerun. Cancellation must validate ownership/status, restore stock exactly once and record the event.

Proposed lifecycle:

```text
Pending → Confirmed → Processing → Shipped → Delivered
   └────→ Cancelled
```

Customers may cancel Pending orders only. The architecture policy permits admin cancellation before shipment, including Confirmed/Processing orders. Delivered and Cancelled are terminal; post-shipment cancellation is outside this policy.

## Security and email-abuse contract

- Private profiles, carts and orders require authenticated, UID-scoped access.
- Customers cannot grant roles, change stock/totals/status or manage another customer's data.
- Trusted setup assigns admin claims; hidden UI controls are insufficient authorization.
- Backend validation owns privileged catalog, stock and order operations.
- Explicitly check backend ownership/roles because Admin SDK operations bypass Firestore rules.
- Protected callable operations require authentication where applicable and [App Check enforcement](https://firebase.google.com/docs/app-check/cloud-functions).
- Control recipients, purposes, templates and content server-side; do not provide an arbitrary email relay.
- Enforce UID/recipient/network limits, resend cooldown, expiry, attempt ceilings and aggregate quotas.
- Store keyed OTP digests, consume challenges atomically and prevent replay.
- Never log codes, reset links, passwords, keys or tokens. Use generic reset responses to avoid account enumeration.

A key embedded in the mobile app is extractable and cannot replace abuse controls. `OTP_HMAC_SECRET` protects server-side challenge digests; it is not a mobile access token.

## Catalog setup requirements

Prepare at least 15 products across four categories. The catalog specification proposes 16 products across Electronics, Clothing, Home & Kitchen and Personal Care; these category names are design choices.

Each product requires a deterministic ID, meaningful description, stable permitted image URL, category, integer PKR price, stock and active state. Include unavailable/inactive fixtures for validation while retaining enough active products for browsing.

Validate seed records and references against an emulator first. Use trusted setup and idempotent IDs; avoid overwriting live inventory on reruns. Confirm the target before production writes. Assign admin roles separately and never distribute hardcoded admin passwords. These are dataset/setup requirements, not certification of an uploaded catalog or an executable seed script.

## UI/UX standards

Use restrained colors, clear typography, consistent spacing and product-focused layouts. Avoid decorative gradients, glass effects and excessive shadows. Support small screens, safe areas, keyboard avoidance, readable contrast, large text and accessible touch targets.

Loading, empty, error, success, unavailable and recovery states belong in each relevant flow. Preserve input/cart during recoverable failures. Use subtle motion where it clarifies navigation or feedback.

## Validation and builds

Static analysis from `flutter_app/`:

```sh
flutter analyze
```

For an available Flutter test suite:

```sh
flutter test
```

Build commands from `flutter_app/`:

```sh
flutter build apk --release
flutter build ios --release --no-codesign
```

Conventional APK location: `flutter_app/build/app/outputs/flutter-apk/app-release.apk`. Distribution requires appropriate release signing; a no-codesign iOS build is not an installable signed application.

Required evidence covers auth/session/reset, browse/filter/sort states, cart arithmetic/persistence, invalid delivery/quantity input, order snapshots, final-unit concurrency, retry without duplicate orders, cross-user denial, privilege escalation denial and cancellation/restock consistency. Email tests must cover expiry, replay, recipient binding and throttling using mocked sends.

Recorded checks: Flutter analysis passed with no issues. Platform IDs/labels, Android/iOS-only targets, iOS configuration syntax and the unchanged assignment PDF copy were verified. Build/test commands here are instructions, not claims of completed feature tests or generated release artifacts. Detailed evidence belongs in the local task tracker.

## Assignment submission requirements

- Complete modular Flutter source and backend source where used.
- Installable APK with environment/run instructions.
- Package, Firebase, schema, money and security documentation.
- Firestore rules and access-control test evidence.
- Category/product dataset with reproducible seed/setup instructions.
- Key customer/admin screenshots and actual test results.
- A 5–7 minute demo showing customer/admin flow, orders, stock integrity and security.
- Explicit limitations and AI disclosure; exclude passwords, service accounts and private keys.

Attach verified screenshots, APK and demo links to the release deliverables. No fabricated download links or evidence are included here.

## Scope and limitations

Platforms are Android and iOS. Payment is simulated Cash on Delivery without a real gateway. The small-catalog design uses in-memory name search/filter/sort; larger catalogs require a revised search/query strategy. Images depend on selected URL availability and licensing. Email depends on verified senders, provider quotas and backend abuse controls. Configuration instructions are not certification that product requirements have been satisfied.

## Documentation and working agreement

Local `docs/` contains the assignment PDF, `PRD.md`, `ARCHITECTURE.md`, `DESIGN.md`, `AGENTS.md`, `TASK_TRACKER.md`, `SETUP.md`, `SECURITY.md`, `DATA_MODEL.md` and `TEST_PLAN.md`. Read root/local agent instructions before changing the project.

After the initial repository setup, every Git command requires the owner's explicit permission. Documentation edits do not authorize a commit or push.

## AI assistance

Codex assisted with assignment review, project initialization and documentation. Flutter generated the platform scaffold. Assess delivered functionality and test evidence from source and actual validation records rather than inferring completion from this README.
