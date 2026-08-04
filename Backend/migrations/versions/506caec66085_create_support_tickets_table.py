"""Create support_tickets table

Revision ID: 506caec66085
Revises: 505baec66084
Create Date: 2026-08-04 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '506caec66085'
down_revision = '505baec66084'
branch_labels = None
depends_on = None


def upgrade() -> None:
    ticket_type = postgresql.ENUM('bug', 'feature', 'feedback', name='supporttickettype', create_type=False)
    ticket_type.create(op.get_bind(), checkfirst=True)

    ticket_status = postgresql.ENUM('open', 'closed', name='supportticketstatus', create_type=False)
    ticket_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        'support_tickets',
        sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('type', ticket_type, nullable=False),
        sa.Column('title', sa.String(length=200), nullable=True),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('rating', sa.Integer(), nullable=True),
        sa.Column('screenshot_url', sa.Text(), nullable=True),
        sa.Column('status', ticket_status, server_default='open', nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('idx_support_tickets_user_id', 'support_tickets', ['user_id'])


def downgrade() -> None:
    op.drop_index('idx_support_tickets_user_id')
    op.drop_table('support_tickets')
    op.execute('DROP TYPE IF EXISTS supporttickettype')
    op.execute('DROP TYPE IF EXISTS supportticketstatus')
