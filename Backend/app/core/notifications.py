"""Firebase Cloud Messaging notifications."""
import json
import logging
import sys
import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings
from datetime import datetime

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
_firebase_app = None


def _initialize_firebase():
    """Initialize Firebase Admin SDK from environment variable."""
    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    try:
        # Parse service account JSON from environment variable
        service_account_json = settings.FIREBASE_SERVICE_ACCOUNT_JSON
        service_account_dict = json.loads(service_account_json)

        # Initialize Firebase Admin
        cred = credentials.Certificate(service_account_dict)
        _firebase_app = firebase_admin.initialize_app(cred)
        print(f"[FIREBASE] Initialized successfully (project: {service_account_dict.get('project_id', 'unknown')})")
        logger.info("Firebase Admin SDK initialized successfully")
        return _firebase_app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise




def send_push_notification(fcm_token: str, title: str, body: str, data_payload: dict = None, user_id = None, notification_id = None) -> bool:
    """
    Send a push notification via Firebase Cloud Messaging.

    Args:
        fcm_token: Device FCM token
        title: Notification title
        body: Notification body
        data_payload: Optional dict of additional data to send
        user_id: Optional user ID for logging
        notification_id: Optional notification ID for logging

    Returns:
        True if sent successfully, False otherwise
    """
    print(f"[FCM] send_push_notification() called: token={fcm_token[:20]}..., user_id={user_id}, notif_id={notification_id}", file=sys.stderr)

    if not fcm_token:
        logger.warning("Cannot send notification: fcm_token is empty")
        print(f"[FCM] ERROR: Cannot send notification - fcm_token is empty", file=sys.stderr)
        return False

    try:
        _initialize_firebase()

        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body
            ),
            data=data_payload or {},
            token=fcm_token
        )

        print(f"[FCM] Calling firebase_admin.messaging.send() with token={fcm_token[:20]}...", file=sys.stderr)
        response = messaging.send(message)
        logger.info(f"Push notification sent successfully: {response}")
        print(f"[FCM] SUCCESS - Firebase message ID: {response}", file=sys.stderr)

        # Log to database
        if user_id:
            try:
                from app.database import SessionLocal
                from app.models import FirebaseLog
                db_log = SessionLocal()
                log = FirebaseLog(
                    user_id=user_id,
                    notification_id=notification_id,
                    fcm_token=fcm_token,
                    status="sent",
                    message_id=str(response),
                    created_at=datetime.utcnow()
                )
                db_log.add(log)
                db_log.commit()
                db_log.close()
                print(f"[FCM-LOGGED] Firebase call recorded in firebase_logs", file=sys.stderr)
            except Exception as log_err:
                print(f"[FCM-LOG-ERROR] Failed to log: {type(log_err).__name__}: {log_err}", file=sys.stderr)

        return True
    except messaging.InvalidArgumentError as e:
        logger.warning(f"Invalid FCM token or message: {e}")
        print(f"[FCM] InvalidArgumentError: {e}", file=sys.stderr)

        # Log to database
        if user_id:
            try:
                from app.database import SessionLocal
                from app.models import FirebaseLog
                db_log = SessionLocal()
                log = FirebaseLog(
                    user_id=user_id,
                    notification_id=notification_id,
                    fcm_token=fcm_token,
                    status="error",
                    error_type="InvalidArgumentError",
                    error_message=str(e),
                    created_at=datetime.utcnow()
                )
                db_log.add(log)
                db_log.commit()
                db_log.close()
            except Exception as log_err:
                print(f"[FCM-LOG-ERROR] Failed to log error: {log_err}", file=sys.stderr)

        return False
    except messaging.UnregisteredError as e:
        logger.warning(f"FCM token is unregistered/expired: {e}")
        print(f"[FCM] UnregisteredError: {e}", file=sys.stderr)

        # Log to database
        if user_id:
            try:
                from app.database import SessionLocal
                from app.models import FirebaseLog
                db_log = SessionLocal()
                log = FirebaseLog(
                    user_id=user_id,
                    notification_id=notification_id,
                    fcm_token=fcm_token,
                    status="error",
                    error_type="UnregisteredError",
                    error_message=str(e),
                    created_at=datetime.utcnow()
                )
                db_log.add(log)
                db_log.commit()
                db_log.close()
            except Exception as log_err:
                print(f"[FCM-LOG-ERROR] Failed to log error: {log_err}", file=sys.stderr)

        return False
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        print(f"[FCM] EXCEPTION: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)

        # Log to database
        if user_id:
            try:
                from app.database import SessionLocal
                from app.models import FirebaseLog
                db_log = SessionLocal()
                log = FirebaseLog(
                    user_id=user_id,
                    notification_id=notification_id,
                    fcm_token=fcm_token,
                    status="error",
                    error_type=type(e).__name__,
                    error_message=str(e),
                    created_at=datetime.utcnow()
                )
                db_log.add(log)
                db_log.commit()
                db_log.close()
            except Exception as log_err:
                print(f"[FCM-LOG-ERROR] Failed to log error: {log_err}", file=sys.stderr)

        return False
