import os

os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("FIREBASE_PROJECT_ID", "easypdf-test")
os.environ.setdefault("APP_ENV", "test")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.auth import CurrentUser, get_current_user
from app.database import get_db
from app.main import app
from app.models import Base

engine = create_engine(
    "sqlite+pysqlite:///:memory:",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSession = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
current_uid = "test-user"


def test_user_dependency() -> CurrentUser:
    return CurrentUser(uid=current_uid, email="test@example.com", display_name="Test")


def override_get_db():
    with TestSession() as session:
        yield session


@pytest.fixture
def client():
    global current_uid
    current_uid = "test-user"
    Base.metadata.create_all(bind=engine)
    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = test_user_dependency
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)
