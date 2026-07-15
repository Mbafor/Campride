"""Add DriverCurrentRoute model

Revision ID: 30844dca457d
Revises: 503baec66080
Create Date: 2026-07-15 16:17:47.431837

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '30844dca457d'
down_revision = '503baec66080'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table('driver_current_routes',
    sa.Column('id', postgresql.UUID(as_uuid=True), server_default=sa.text('gen_random_uuid()'), nullable=False),
    sa.Column('driver_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('route_id', postgresql.UUID(as_uuid=True), nullable=True),
    sa.Column('created_at', postgresql.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
    sa.Column('updated_at', postgresql.TIMESTAMP(), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
    sa.ForeignKeyConstraint(['driver_id'], ['users.id'], name=op.f('driver_current_routes_driver_id_fkey'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['route_id'], ['routes.id'], name=op.f('driver_current_routes_route_id_fkey'), ondelete='SET NULL'),
    sa.PrimaryKeyConstraint('id', name=op.f('driver_current_routes_pkey')),
    sa.UniqueConstraint('driver_id', name=op.f('driver_current_routes_driver_id_key'))
    )
    op.create_index(op.f('ix_driver_current_routes_driver_id'), 'driver_current_routes', ['driver_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_driver_current_routes_driver_id'), table_name='driver_current_routes')
    op.drop_table('driver_current_routes')
