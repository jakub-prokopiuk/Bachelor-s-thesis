import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
import os

def generate_random_password(length=8):
    """Generates a random password of a given length."""
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for i in range(length))

def send_reset_email(email: str, new_password: str):
    """Sends a password reset email to the user."""

    load_dotenv()
    SENDER_EMAIL = os.getenv("SENDER_EMAIL")
    SENDER_SMTP = os.getenv("SENDER_SMTP")
    SENDER_PASSWORD = os.getenv("SENDER_PASSWORD")
    sender_email = SENDER_EMAIL
    receiver_email = email
    subject = "WattWay Password Reset"
    body = f"""
    Hello,
    we've received a request to reset your password. Your new password is: {new_password}. Please change it after logging in.
    
    Best regards,
    WattWay Team
    """

    msg = MIMEMultipart()
    msg['From'] = sender_email
    msg['To'] = receiver_email
    msg['Subject'] = subject
    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP_SSL(SENDER_SMTP, 465) as server:
            server.login(sender_email, SENDER_PASSWORD)
            server.sendmail(sender_email, receiver_email, msg.as_string())
    except Exception as e:
        raise Exception(f"Error sending email: {str(e)}")
