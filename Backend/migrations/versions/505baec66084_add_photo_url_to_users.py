"""Add photo_url to users

Revision ID: 505baec66084
Revises: 502f5c66082
Create Date: 2026-08-03 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '505baec66084'
down_revision = '502f5c66082'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column('users', sa.Column('photo_url', sa.Text(), nullable=True))


def downgrade():
    op.drop_column('users', 'photo_url')
