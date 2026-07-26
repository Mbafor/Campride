"""Notification management endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import SessionLocal
from app.models import Notification, User
from app.api.deps import get_db, get_current_user
from app.schemas.notification import NotificationResponse, NotificationListResponse

router = APIRouter(prefix="/api/v1/notifications", tags=["notifications"])


@router.get("", response_model=NotificationListResponse)
def list_notifications(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all notifications for the current authenticated user, ordered most recent first."""
    notifications = db.query(Notification).filter(
        Notification.user_id == current_user.id
    ).order_by(Notification.created_at.desc()).all()

    return NotificationListResponse(
        notifications=[NotificationResponse.from_orm(n) for n in notifications]
    )


@router.get("/unread-count")
def get_unread_count(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get count of unread notifications for the current user."""
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()

    return {"unread_count": count}


@router.put("/{notification_id}/read")
def mark_notification_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Mark a single notification as read. User can only mark their own notifications."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id
    ).first()

    if not notification:
        raise HTTPException(status_code=404, detail={"error_code": "NOTIF_001", "message": "Notification not found"})

    # Verify ownership - user can only mark their own notifications as read
    if notification.user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail={"error_code": "NOTIF_002", "message": "You do not have permission to update this notification"}
        )

    notification.is_read = True
    db.commit()
    db.refresh(notification)

    return NotificationResponse.from_orm(notification)
