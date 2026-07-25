"""Add last_notification_level to shuttle_requests table

Revision ID: 502f5c66081
Revises: 30844dca457d
Create Date: 2026-07-25 19:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '502f5c66081'
down_revision = '30844dca457d'
branch_labels = None
depends_on = None


def upgrade():
    # Add last_notification_level column to shuttle_requests
    op.add_column('shuttle_requests', sa.Column('last_notification_level', sa.String(), nullable=True))


def downgrade():
    # Remove last_notification_level column
    op.drop_column('shuttle_requests', 'last_notification_level')
