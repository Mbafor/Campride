"""Create verification_codes table

Revision ID: 503baec66080
Revises: 502baec66079
Create Date: 2026-07-14 21:56:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '503baec66080'
down_revision = '502baec66079'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'verification_codes',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('code', sa.String(6), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_verification_codes_user_id', 'verification_codes', ['user_id'])
    op.create_index('idx_verification_codes_code', 'verification_codes', ['code'])


def downgrade() -> None:
    op.drop_index('idx_verification_codes_code')
    op.drop_index('idx_verification_codes_user_id')
    op.drop_table('verification_codes')
