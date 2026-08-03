"""Add phone_number column to users table

Revision ID: 504baec66083
Revises: 502f5c66082
Create Date: 2026-08-03 12:45:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '504baec66083'
down_revision = '502f5c66082'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('phone_number', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'phone_number')
