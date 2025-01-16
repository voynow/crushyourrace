import base64
import logging
import os
import time
import traceback

import httpx
import jwt
from dotenv import load_dotenv
from src.supabase_client import get_user
from src.types.user import User

load_dotenv()


logger = logging.getLogger()
logger.setLevel(logging.INFO)


def generate_jwt_token(key_id: str, team_id: str, private_key: str) -> str:
    """
    Generate JWT token for APNs authentication.

    :param key_id: Apple Key ID
    :param team_id: Apple Team ID
    :param private_key: Contents of the .p8 file
    :return: JWT token as a string
    """
    headers = {"alg": "ES256", "kid": key_id}
    payload = {"iss": team_id, "iat": time.time()}
    return jwt.encode(payload, private_key, algorithm="ES256", headers=headers)


def send_push_notification(device_token: str, title: str, body: str):
    """
    Send a push notification to a user's device.

    :param device_token: User's device token
    :param title: Notification title
    :param body: Notification body
    :raises ValueError: If device token is invalid
    """
    # Validate device token format
    clean_token = device_token.strip().replace(" ", "")
    if (
        not clean_token
        or len(clean_token) != 64
        or not all(c in "0123456789abcdefABCDEF" for c in clean_token)
    ):
        raise ValueError(f"Invalid device token format: {device_token}")

    logging.info(
        f"Sending push notification with token: {clean_token[:8]}..."
    )  # Log first 8 chars for debugging

    auth_token = generate_jwt_token(
        key_id=os.environ["APN_KEY_ID"],
        team_id=os.environ["APN_TEAM_ID"],
        private_key=base64.b64decode(os.environ["APN_PRIVATE_KEY"]).decode(),
    )

    base_url = "api.push.apple.com"
    url = f"https://{base_url}/3/device/{clean_token}"
    headers = {
        "Authorization": f"Bearer {auth_token}",
        "apns-topic": "voynow.mobile",
        "content-type": "application/json",
    }
    payload = {
        "aps": {
            "alert": {"title": title, "body": body},
            "sound": "default",
        }
    }

    try:
        client = httpx.Client(http2=True, verify=True, timeout=30.0)
        response = client.post(url, json=payload, headers=headers)
        response.raise_for_status()
        client.close()

    except httpx.RequestError as e:
        logging.error(f"Connection error: {e}")
        raise
    except httpx.HTTPStatusError:
        error_payload = response.json() if response.content else "No error details"
        logging.error(f"APNs error: {response.status_code}, {error_payload}")
        raise ValueError(f"APNs rejected the request: {error_payload}")

    return response


def send_push_notif_wrapper(user: User):
    """Send push notification to user if they have a valid device token."""
    user = get_user(user.athlete_id)
    if not user.device_token:
        logger.info(f"No device token for user {user.athlete_id}")
        return

    try:
        send_push_notification(
            device_token=user.device_token,
            title="Crush Your Race",
            body="Your training week has been updated!",
        )
    except Exception as e:
        logger.error(f"Failed to send push notification to user {user.athlete_id}: {e}")
        logger.error(traceback.format_exc())
        # raise
