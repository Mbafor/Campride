import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings


def send_email(to_email: str, subject: str, body: str) -> bool:
    try:
        msg = MIMEMultipart()
        msg["From"] = settings.GMAIL_ADDRESS
        msg["To"] = to_email
        msg["Subject"] = subject

        msg.attach(MIMEText(body, "plain"))

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(settings.GMAIL_ADDRESS, settings.GMAIL_APP_PASSWORD)
        server.send_message(msg)
        server.quit()
        return True
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
