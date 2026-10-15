import logging
from dataclasses import dataclass
from functools import lru_cache

import firebase_admin
from google.auth.exceptions import GoogleAuthError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth
from firebase_admin.exceptions import FirebaseError
from requests.exceptions import RequestException

from app.config import get_settings

logger = logging.getLogger(__name__)
bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class CurrentUser:
    uid: str
    email: str | None
    display_name: str | None


@lru_cache
def _firebase_app() -> firebase_admin.App:
    project_id = get_settings().firebase_project_id
    try:
        return firebase_admin.get_app()
    except ValueError:
        return firebase_admin.initialize_app(options={"projectId": project_id})


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> CurrentUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="A valid Firebase ID token is required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        claims = firebase_auth.verify_id_token(
            credentials.credentials,
            app=_firebase_app(),
            check_revoked=True,
        )
    except (firebase_auth.InvalidIdTokenError, firebase_auth.ExpiredIdTokenError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="A valid Firebase ID token is required",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None
    except (FirebaseError, GoogleAuthError, RequestException, ValueError) as error:
        logger.warning("Firebase token verification failed: %s", type(error).__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service is temporarily unavailable",
        ) from None

    uid = claims.get("uid")
    if not isinstance(uid, str) or not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="A valid Firebase ID token is required",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return CurrentUser(
        uid=uid,
        email=claims.get("email"),
        display_name=claims.get("name"),
    )
