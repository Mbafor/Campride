"""Firebase Cloud Messaging notifications."""
import json
import logging
import firebase_admin
from firebase_admin import credentials, messaging
from app.core.config import settings

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
        logger.info("Firebase Admin SDK initialized successfully")
        return _firebase_app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise


def send_push_notification(fcm_token: str, title: str, body: str, data_payload: dict = None) -> bool:
    """
    Send a push notification via Firebase Cloud Messaging.

    Args:
        fcm_token: Device FCM token
        title: Notification title
        body: Notification body
        data_payload: Optional dict of additional data to send

    Returns:
        True if sent successfully, False otherwise
    """
    if not fcm_token:
        logger.warning("Cannot send notification: fcm_token is empty")
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

        response = messaging.send(message)
        logger.info(f"Push notification sent successfully: {response}")
        return True
    except messaging.InvalidArgumentError as e:
        logger.warning(f"Invalid FCM token or message: {e}")
        return False
    except messaging.UnregisteredError as e:
        logger.warning(f"FCM token is unregistered/expired: {e}")
        return False
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        return False
