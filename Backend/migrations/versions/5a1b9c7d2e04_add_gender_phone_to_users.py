"""Add gender and phone_number columns to users table

Revision ID: 5a1b9c7d2e04
Revises: 502f5c66082
Create Date: 2026-08-03 22:50:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '5a1b9c7d2e04'
down_revision = '502f5c66082'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR")
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR")


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS phone_number")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS gender")
