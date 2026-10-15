# EasyPDF API

This service provides authenticated account and document-history endpoints.
Firebase Authentication remains the identity provider; the API verifies Firebase
ID tokens and PostgreSQL stores document metadata scoped to the verified user ID.
PDF files are generated and kept on the device. This service does not upload,
back up, or serve PDF bytes.

## Local development

Requirements: Docker Compose and a Firebase Admin service-account JSON file for
the EasyPDF Firebase project. Do not commit that file or put it in the repository.

1. Copy `.env.example` to `.env`, set a unique local database password in both
   `POSTGRES_PASSWORD` and `DATABASE_URL`, and set
   `FIREBASE_SERVICE_ACCOUNT_FILE` to the absolute path of your service-account
   file.
2. Start PostgreSQL with `docker compose up -d db`.
3. Apply migrations with `docker compose run --rm api alembic upgrade head`.
4. Start the API with `docker compose up --build -d api`.
5. Check `http://127.0.0.1:8000/health/live`, then use `/docs` while
   `APP_ENV=development`.

The Compose database port is not published to the host. The API binds only to
loopback for local use. Never expose this development Compose setup directly to
the public internet. For production, use managed PostgreSQL, a managed HTTPS
container platform, workload identity for Firebase Admin, secret management,
backups, monitoring, and a deployment-time `alembic upgrade head`.

## API

- `GET /health/live`: process liveness.
- `GET /health/ready`: PostgreSQL readiness.
- `GET /v1/me`: Firebase-authenticated account claims.
- `GET /v1/documents?limit=20`: list the caller's latest document metadata.
- `POST /v1/documents`: save PDF name, page count, and byte count.
- `DELETE /v1/documents/{id}`: delete the caller's metadata record.

Authenticated routes require `Authorization: Bearer <Firebase ID token>`.
Tokens are verified against the configured Firebase project, including revocation
status. The API never accepts a client-supplied owner ID. Document metadata is
limited and validated; database queries always filter by the verified Firebase
UID.

## Run tests

From this directory, install `requirements-dev.txt` in an isolated Python
environment and run `pytest`. The API tests use an isolated SQLite database;
production and local Compose use PostgreSQL.

## Mobile configuration

Build the app with `--dart-define=EASYPDF_API_BASE_URL=https://<your-api-host>`.
Release builds reject non-HTTPS API URLs. HTTP is accepted only in Flutter debug
builds. The service-account JSON belongs only on the backend, never in the
mobile app.
