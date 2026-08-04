import resend
from app.core.config import settings

resend.api_key = settings.RESEND_API_KEY


def send_email(to_email: str, subject: str, body: str) -> bool:
    try:
        response = resend.Emails.send(
            {
                "from": "CampRide <noreply@cosssached.org>",
                "to": to_email,
                "subject": subject,
                "text": body,
            }
        )

        if response.get("id"):
            return True
        else:
            print(f"[ERROR] Resend API returned no email ID for {to_email}")
            print(f"[ERROR] Response: {response}")
            return False
    except Exception as e:
        import traceback
        print(f"[ERROR] Failed to send email to {to_email}")
        print(f"[ERROR] Exception type: {type(e).__name__}")
        print(f"[ERROR] Exception message: {e}")
        print(f"[ERROR] Traceback:\n{traceback.format_exc()}")
        return False


def send_verification_email(to_email: str, code: str) -> bool:
    subject = "CampRide Email Verification"
    body = f"""Hello,

Your CampRide email verification code is:

{code}

This code will expire in 10 minutes.

If you didn't request this, please ignore this email.

Best regards,
CampRide Team"""

    return send_email(to_email, subject, body)


def send_password_reset_email(to_email: str, code: str) -> bool:
    subject = "CampRide Password Reset Request"
    body = f"""Hello,

You have requested to reset your CampRide password. Your password reset code is:

{code}

This code will expire in 10 minutes.

If you did not request a password reset, please ignore this email or contact us immediately.

Best regards,
CampRide Team"""

    return send_email(to_email, subject, body)
