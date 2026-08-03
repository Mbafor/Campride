"""Add photo_url to users

Revision ID: 505baec66084
Revises: 5a1b9c7d2e04
Create Date: 2026-08-03 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '505baec66084'
down_revision = '5a1b9c7d2e04'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT")


def downgrade():
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS photo_url")
