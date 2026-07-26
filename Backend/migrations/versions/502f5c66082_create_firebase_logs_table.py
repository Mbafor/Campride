"""Create firebase_logs table for auditing FCM calls

Revision ID: 502f5c66082
Revises: 502f5c66081
Create Date: 2026-07-25 19:50:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '502f5c66082'
down_revision = '502f5c66081'
branch_labels = None
depends_on = None


def upgrade():
    # Create firebase_logs table
    op.create_table(
        'firebase_logs',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('notification_id', sa.UUID(), nullable=True),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('fcm_token', sa.String(), nullable=False),
        sa.Column('status', sa.String(), nullable=False),  # 'sent', 'failed', 'error'
        sa.Column('message_id', sa.String(), nullable=True),  # Firebase response
        sa.Column('error_type', sa.String(), nullable=True),
        sa.Column('error_message', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['notification_id'], ['notifications.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
    )


def downgrade():
    op.drop_table('firebase_logs')
