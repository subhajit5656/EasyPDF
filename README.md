# EasyPDF

EasyPDF is a Flutter app for scanning or selecting images, arranging pages, and
creating a PDF on the device. The login page design is kept intact.

## App workflow

1. Sign in with Firebase Authentication.
2. From the dashboard, scan pages or select photos.
3. Replace/reorder pages in the preview and create a PDF.
4. The PDF is saved in the app's private documents directory and can be shared.
5. If the API is configured, the signed-in account's recent history syncs the
   PDF name, page count, file size, and creation time.

The PDF itself is not uploaded. Removing an item from history removes only its
metadata, not the local file.

## Stack

- **Mobile:** Flutter and Dart.
- **Identity:** Firebase Authentication (email/password and Google sign-in).
- **API:** FastAPI with Firebase Admin ID-token verification.
- **Database:** PostgreSQL, managed with SQLAlchemy and Alembic migrations.
- **PDF processing:** on-device image/PDF packages; document data remains local.

See [backend/README.md](backend/README.md) for local setup, API endpoints, tests,
and deployment boundaries.

See [docs/PROJECT_RCA_SECURITY_SDLC.md](docs/PROJECT_RCA_SECURITY_SDLC.md) for
the source-level RCA, DFD, request lifecycle, SDLC/release gates, security
follow-ups, and hosting-cost notes.

## Production and Play Store release checklist

The repository is not a one-command production release. Before launch:

- Deploy the API behind HTTPS with managed PostgreSQL, Firebase workload
  identity, secret management, encrypted backups, monitoring, and migrations.
- Build with
  `--dart-define=EASYPDF_API_BASE_URL=https://<your-api-host>`.
- Create a unique Android upload keystore, copy
  `android/key.properties.example` to `android/key.properties`, and use the
  real secret values. Keep the keystore and properties file backed up securely
  and out of Git. Release signing no longer falls back to the debug key.
- Check that the Firebase Android app, Google sign-in SHA fingerprints, OAuth
  configuration, and production Firebase project are correct.
- Complete Play Console Data safety, privacy policy, account deletion,
  permissions, target SDK, content rating, store listing, and testing-track
  requirements for the exact release.
- Implement and test account deletion in the app and publish the required web
  deletion-request route before enabling account creation in a Play release.
- Test install, sign-in/out, camera/gallery permissions, multi-page PDF
  generation, sharing, API outages, and account data deletion on supported
  Android versions and physical devices.

No source change can guarantee Play Store approval. Google Play policy,
account configuration, current target-SDK requirements, release signing, and
the submitted store listing must all be checked in Play Console before release.
