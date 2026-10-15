import app.auth as api_auth
from app.auth import CurrentUser, get_current_user
from app.config import Settings


def test_health_endpoints(client):
    assert client.get("/health/live").json() == {"status": "ok"}
    assert client.get("/health/ready").json() == {"status": "ready"}


def test_api_docs_are_disabled_outside_development(client, monkeypatch):
    monkeypatch.delenv("APP_ENV", raising=False)
    settings = Settings(
        _env_file=None,
        database_url="sqlite+pysqlite:///:memory:",
        firebase_project_id="easypdf-test",
    )
    assert settings.app_env == "production"
    assert client.app.docs_url is None
    assert client.app.redoc_url is None
    assert client.app.openapi_url is None
    assert client.get("/docs").status_code == 404


def test_document_endpoints_require_authentication(client):
    client.app.dependency_overrides.pop(get_current_user)
    response = client.get("/v1/documents")
    assert response.status_code == 401


def test_me_returns_verified_firebase_claims(client, monkeypatch):
    client.app.dependency_overrides.pop(get_current_user)
    monkeypatch.setattr(api_auth, "_firebase_app", lambda: object())
    monkeypatch.setattr(
        api_auth.firebase_auth,
        "verify_id_token",
        lambda token, **kwargs: {
            "uid": "verified-user",
            "email": "user@example.com",
            "name": "Verified User",
        },
    )

    response = client.get(
        "/v1/me",
        headers={"Authorization": "Bearer valid-test-token"},
    )
    assert response.status_code == 200
    assert response.json() == {
        "uid": "verified-user",
        "email": "user@example.com",
        "display_name": "Verified User",
    }


def test_invalid_firebase_token_is_rejected(client, monkeypatch):
    client.app.dependency_overrides.pop(get_current_user)
    monkeypatch.setattr(api_auth, "_firebase_app", lambda: object())

    def reject_token(*args, **kwargs):
        raise api_auth.firebase_auth.InvalidIdTokenError("invalid")

    monkeypatch.setattr(api_auth.firebase_auth, "verify_id_token", reject_token)
    response = client.get(
        "/v1/me",
        headers={"Authorization": "Bearer invalid-test-token"},
    )
    assert response.status_code == 401


def test_malformed_firebase_claims_are_rejected(client, monkeypatch):
    client.app.dependency_overrides.pop(get_current_user)
    monkeypatch.setattr(api_auth, "_firebase_app", lambda: object())
    monkeypatch.setattr(
        api_auth.firebase_auth,
        "verify_id_token",
        lambda token, **kwargs: {"uid": "verified-user", "email": ["not", "a string"]},
    )

    response = client.get(
        "/v1/me",
        headers={"Authorization": "Bearer test-token"},
    )
    assert response.status_code == 401


def test_documents_are_owned_by_authenticated_user(client):
    response = client.post(
        "/v1/documents",
        json={
            "file_name": "scan.pdf",
            "page_count": 2,
            "file_size_bytes": 2048,
        },
    )
    assert response.status_code == 201
    created = response.json()
    assert created["file_name"] == "scan.pdf"

    assert client.get("/v1/documents").json()[0]["id"] == created["id"]
    assert client.delete(f"/v1/documents/{created['id']}").status_code == 204
    assert client.get("/v1/documents").json() == []

    app = client.app
    response = client.post(
        "/v1/documents",
        json={
            "file_name": "other.pdf",
            "page_count": 1,
            "file_size_bytes": 512,
        },
    )
    other_document_id = response.json()["id"]
    app.dependency_overrides[get_current_user] = lambda: CurrentUser(
        uid="different-user", email=None, display_name=None
    )
    assert client.get("/v1/documents").json() == []
    assert client.delete(f"/v1/documents/{other_document_id}").status_code == 404


def test_document_name_must_not_include_path(client):
    response = client.post(
        "/v1/documents",
        json={
            "file_name": "../private.pdf",
            "page_count": 1,
            "file_size_bytes": 100,
        },
    )
    assert response.status_code == 422


def test_document_limits_are_validated(client):
    response = client.post(
        "/v1/documents",
        json={
            "file_name": "scan.pdf",
            "page_count": 0,
            "file_size_bytes": 100,
        },
    )
    assert response.status_code == 422

    response = client.post(
        "/v1/documents",
        json={
            "file_name": "scan.pdf",
            "page_count": 51,
            "file_size_bytes": 100,
        },
    )
    assert response.status_code == 422


def test_client_cannot_set_document_owner(client):
    response = client.post(
        "/v1/documents",
        json={
            "file_name": "scan.pdf",
            "page_count": 1,
            "file_size_bytes": 100,
            "owner_uid": "another-user",
        },
    )
    assert response.status_code == 422
