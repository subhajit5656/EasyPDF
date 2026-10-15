from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class UserResponse(BaseModel):
    uid: str
    email: str | None
    display_name: str | None


class DocumentCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    file_name: str = Field(min_length=5, max_length=120)
    page_count: int = Field(ge=1, le=50)
    file_size_bytes: int = Field(ge=1, le=104_857_600)

    @field_validator("file_name")
    @classmethod
    def validate_file_name(cls, value: str) -> str:
        value = value.strip()
        if (
            len(value) < 5
            or value in {".", ".."}
            or "/" in value
            or "\\" in value
            or not value.lower().endswith(".pdf")
        ):
            raise ValueError("file_name must be a PDF name without a path")
        return value


class DocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    file_name: str
    page_count: int
    file_size_bytes: int
    created_at: datetime
