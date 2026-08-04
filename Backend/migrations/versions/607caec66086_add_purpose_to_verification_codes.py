"""Add purpose column to verification_codes table

Revision ID: 607caec66086
Revises: 506caec66085
Create Date: 2026-08-04 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '607caec66086'
down_revision = '506caec66085'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE verification_codes ADD COLUMN IF NOT EXISTS purpose VARCHAR DEFAULT 'email_verification' NOT NULL")


def downgrade() -> None:
    op.execute("ALTER TABLE verification_codes DROP COLUMN IF EXISTS purpose")
