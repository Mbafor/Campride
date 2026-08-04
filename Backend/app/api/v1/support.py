"""Support ticket endpoints (bug reports, feature requests, feedback)."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.models import User, SupportTicket, SupportTicketType
from app.schemas.support import SupportTicketRequest, SupportTicketResponse
from app.api.deps import get_db, get_current_user
from app.core.email import send_email
from app.core.config import settings

router = APIRouter(prefix="/api/v1/support", tags=["support"])

_TYPE_LABELS = {
    SupportTicketType.bug: "Bug report",
    SupportTicketType.feature: "Feature request",
    SupportTicketType.feedback: "Feedback",
}


@router.post("/tickets", response_model=SupportTicketResponse)
def create_support_ticket(
    request: SupportTicketRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Persist a support ticket and notify the support inbox by email.

    Required fields differ by type: bug/feature need a title and
    description; feedback needs a 1-5 rating with an optional comment.
    """
    try:
        ticket_type = SupportTicketType(request.type)
    except ValueError:
        raise HTTPException(
            status_code=400,
            detail={"error_code": "SUPPORT_001", "message": "Invalid ticket type"},
        )

    title = request.title.strip() if request.title else None
    message = request.message.strip() if request.message else None
    rating = request.rating

    if ticket_type in (SupportTicketType.bug, SupportTicketType.feature):
        if not title:
            raise HTTPException(
                status_code=400,
                detail={"error_code": "SUPPORT_002", "message": "Title cannot be empty"},
            )
        if not message:
            raise HTTPException(
                status_code=400,
                detail={"error_code": "SUPPORT_003", "message": "Description cannot be empty"},
            )
    elif ticket_type == SupportTicketType.feedback:
        if rating is None or not (1 <= rating <= 5):
            raise HTTPException(
                status_code=400,
                detail={"error_code": "SUPPORT_004", "message": "Rating must be between 1 and 5"},
            )

    ticket = SupportTicket(
        user_id=current_user.id,
        type=ticket_type,
        title=title,
        message=message,
        rating=rating,
        screenshot_url=request.screenshot_data_url,
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)

    label = _TYPE_LABELS[ticket_type]
    body_lines = [
        f"Type: {label}",
        f"From: {current_user.name} <{current_user.email}>",
        f"Ticket ID: {ticket.id}",
    ]
    if title:
        body_lines.append(f"Title: {title}")
    if rating is not None:
        body_lines.append(f"Rating: {rating}/5")
    if ticket.screenshot_url:
        body_lines.append("Screenshot: attached to ticket record")
    body_lines.append("")
    body_lines.append(message or "(no comment)")

    send_email(
        to_email=settings.SUPPORT_EMAIL,
        subject=f"[CampRide Support] {label} from {current_user.name}",
        body="\n".join(body_lines),
    )

    return ticket
