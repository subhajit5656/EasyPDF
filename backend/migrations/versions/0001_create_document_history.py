"""Create per-user PDF metadata.

Revision ID: 0001_documents
Revises:
"""
from alembic import op
import sqlalchemy as sa

revision = "0001_documents"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "documents",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("owner_uid", sa.String(length=128), nullable=False),
        sa.Column("file_name", sa.String(length=120), nullable=False),
        sa.Column("page_count", sa.Integer(), nullable=False),
        sa.Column("file_size_bytes", sa.BigInteger(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.CheckConstraint(
            "page_count > 0 AND page_count <= 50",
            name="ck_documents_page_count_positive",
        ),
        sa.CheckConstraint(
            "file_size_bytes > 0", name="ck_documents_file_size_positive"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_documents_owner_created",
        "documents",
        ["owner_uid", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_documents_owner_created", table_name="documents")
    op.drop_table("documents")
