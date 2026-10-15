from uuid import UUID

from fastapi import Depends, FastAPI, HTTPException, Query, Response, status
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.auth import CurrentUser, get_current_user
from app.config import get_settings
from app.database import get_db
from app.models import Document
from app.schemas import DocumentCreate, DocumentResponse, UserResponse

settings = get_settings()
app = FastAPI(
    title="EasyPDF API",
    version="1.0.0",
    docs_url="/docs" if settings.app_env == "development" else None,
    redoc_url="/redoc" if settings.app_env == "development" else None,
    openapi_url="/openapi.json" if settings.app_env == "development" else None,
)


@app.get("/health/live", tags=["health"])
def liveness() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/health/ready", tags=["health"])
def readiness(session: Session = Depends(get_db)) -> dict[str, str]:
    try:
        session.execute(text("SELECT 1"))
    except SQLAlchemyError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database is temporarily unavailable",
        ) from None
    return {"status": "ready"}


@app.get("/v1/me", response_model=UserResponse, tags=["account"])
def get_me(user: CurrentUser = Depends(get_current_user)) -> UserResponse:
    return UserResponse(uid=user.uid, email=user.email, display_name=user.display_name)


@app.get("/v1/documents", response_model=list[DocumentResponse], tags=["documents"])
def list_documents(
    limit: int = Query(default=20, ge=1, le=100),
    session: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
) -> list[Document]:
    return list(
        session.query(Document)
        .filter(Document.owner_uid == user.uid)
        .order_by(Document.created_at.desc(), Document.id.desc())
        .limit(limit)
    )


@app.post(
    "/v1/documents",
    response_model=DocumentResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["documents"],
)
def create_document(
    document: DocumentCreate,
    session: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
) -> Document:
    saved = Document(owner_uid=user.uid, **document.model_dump())
    session.add(saved)
    session.commit()
    session.refresh(saved)
    return saved


@app.delete(
    "/v1/documents/{document_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    tags=["documents"],
)
def delete_document(
    document_id: UUID,
    session: Session = Depends(get_db),
    user: CurrentUser = Depends(get_current_user),
) -> Response:
    saved = (
        session.query(Document)
        .filter(Document.id == str(document_id), Document.owner_uid == user.uid)
        .one_or_none()
    )
    if saved is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    session.delete(saved)
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
