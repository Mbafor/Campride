"""Add email verification fields to users table

Revision ID: 502baec66079
Revises: 001
Create Date: 2026-07-14 21:55:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '502baec66079'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('is_verified', sa.Boolean(), server_default='false', nullable=False))
    op.alter_column('users', 'hashed_password', existing_type=sa.String(), nullable=True)


def downgrade() -> None:
    op.alter_column('users', 'hashed_password', existing_type=sa.String(), nullable=False)
    op.drop_column('users', 'is_verified')
