import logging
import os

import jwt
from fastapi import HTTPException, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from src import supabase_client
from src.constants import DEFAULT_ATHLETE_ID, DEFAULT_USER_ID
from src.types.user import User
from stravalib.client import Client

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logging.getLogger("stravalib.protocol").setLevel(logging.ERROR)

bearer_scheme = HTTPBearer()
strava_client = Client()


def generate_jwt(athlete_id: int, expires_at: int) -> str:
    """
    Generate a JWT token using athlete_id and expiration time, aligning token
    expiration cycle with the athlete's Strava token

    :param athlete_id: strava internal identifier
    :param expires_at: expiration time of strava token
    :return: str
    """
    payload = {"athlete_id": athlete_id, "exp": expires_at}
    token = jwt.encode(payload, os.environ["JWT_SECRET"], algorithm="HS256")
    return token


def decode_jwt(jwt_token: str, verify_exp: bool = True) -> int:
    """
    Decode JWT token and return athlete_id

    :param jwt_token: JWT token
    :param verify_exp: whether to verify expiration
    :return: int if successful, None if decoding fails
    :raises: jwt.DecodeError if token is invalid
    """
    payload = jwt.decode(
        jwt_token,
        os.environ["JWT_SECRET"],
        algorithms=["HS256"],
        options={"verify_exp": verify_exp},
    )
    return payload["athlete_id"]


def refresh_and_update_user_token(athlete_id: int, refresh_token: str) -> User:
    """
    Refresh the user's Strava token and update database

    :param athlete_id: strava internal identifier
    :param refresh_token: refresh token for Strava API
    :return: User
    """
    logger.info(f"Refreshing and updating token for athlete {athlete_id}")
    access_info = strava_client.refresh_access_token(
        client_id=os.environ["STRAVA_CLIENT_ID"],
        client_secret=os.environ["STRAVA_CLIENT_SECRET"],
        refresh_token=refresh_token,
    )

    new_jwt_token = generate_jwt(
        athlete_id=athlete_id, expires_at=access_info["expires_at"]
    )

    existing_user = supabase_client.get_user(athlete_id)

    user = User(
        athlete_id=athlete_id,
        access_token=access_info["access_token"],
        refresh_token=access_info["refresh_token"],
        expires_at=access_info["expires_at"],
        jwt_token=new_jwt_token,
        device_token=supabase_client.get_device_token(athlete_id),
        email=existing_user.email,
        preferences=existing_user.preferences,
        is_premium=existing_user.is_premium,
        user_id=existing_user.user_id,
        identity_token=existing_user.identity_token,
        created_at=existing_user.created_at,
    )

    supabase_client.upsert_user(user)
    return user


def validate_and_refresh_token(token: str) -> int:
    """
    Validate and refresh the user's credentials in DB

    :param token: JWT token
    :return: athlete_id
    """
    try:
        athlete_id = decode_jwt(token)
    except jwt.ExpiredSignatureError:
        try:
            # If the token is expired, decode athlete_id and refresh
            athlete_id = decode_jwt(token, verify_exp=False)
            user = supabase_client.get_user(athlete_id)
            refresh_and_update_user_token(
                athlete_id=athlete_id, refresh_token=user.refresh_token
            )
        except jwt.DecodeError:
            logger.error("Invalid JWT token")
            raise HTTPException(status_code=401, detail="Invalid JWT token")
        except Exception as e:
            logger.error(
                f"Unknown error validating and refreshing token: {e}",
                exc_info=True,
            )
            raise HTTPException(status_code=500, detail="Internal server error")
    except jwt.DecodeError:
        logger.error("Invalid JWT token")
        raise HTTPException(status_code=401, detail="Invalid JWT token")
    except Exception as e:
        logger.error(
            f"Unknown error validating and refreshing token: {e}",
            exc_info=True,
        )
        raise HTTPException(status_code=500, detail="Internal server error")

    return athlete_id


async def validate_user(
    credentials: HTTPAuthorizationCredentials = Security(bearer_scheme),
) -> User:
    """
    Dependency that validates the JWT token from the Authorization header

    :param credentials: Bearer token credentials
    :return: User
    """
    athlete_id = validate_and_refresh_token(credentials.credentials)
    if athlete_id is None:
        logger.error("Invalid authentication credentials")
        raise HTTPException(
            status_code=401, detail="Invalid authentication credentials"
        )
    return supabase_client.get_user(athlete_id)


def authenticate_athlete(athlete_id: int) -> User:
    """
    Authenticate athlete with valid token, refresh if necessary

    :param athlete_id: strava internal identifier
    :return: User
    """
    user = supabase_client.get_user(athlete_id)
    # if datetime_now_est() < utils.make_tz_aware(user.expires_at):
    #     return user
    return refresh_and_update_user_token(athlete_id, user.refresh_token)


def get_configured_strava_client(user: User) -> Client:
    strava_client.access_token = user.access_token
    strava_client.refresh_token = user.refresh_token
    strava_client.token_expires_at = user.expires_at
    return strava_client


def get_strava_client(athlete_id: int) -> Client:
    """Interface for retrieving a Strava client with valid authentication"""
    user = authenticate_athlete(athlete_id)
    return get_configured_strava_client(user)


def get_strava_token(code: str) -> dict:
    return strava_client.exchange_code_for_token(
        client_id=os.environ["STRAVA_CLIENT_ID"],
        client_secret=os.environ["STRAVA_CLIENT_SECRET"],
        code=code,
    )


def strava_authenticate(code: str) -> User:
    """
    Authenticate athlete with code from Strava, exchange with strava client for
    token, generate new JWT, and update database

    :param code: temporary authorization code
    :return: User
    """
    token = get_strava_token(code)
    strava_client.access_token = token["access_token"]
    strava_client.refresh_token = token["refresh_token"]
    strava_client.token_expires_at = token["expires_at"]

    athlete = strava_client.get_athlete()
    jwt_token = generate_jwt(athlete_id=athlete.id, expires_at=token["expires_at"])

    is_new_user = supabase_client.is_new_user(athlete_id=athlete.id)
    maybe_existing_user = supabase_client.get_or_create_user(
        athlete_id=athlete.id, user_id=DEFAULT_USER_ID
    )

    user = User(
        athlete_id=athlete.id,
        access_token=strava_client.access_token,
        refresh_token=strava_client.refresh_token,
        expires_at=strava_client.token_expires_at,
        jwt_token=jwt_token,
        device_token=supabase_client.get_device_token(athlete.id),
        email=maybe_existing_user.email,
        preferences=maybe_existing_user.preferences,
        is_premium=maybe_existing_user.is_premium,
        user_id=maybe_existing_user.user_id,
        identity_token=maybe_existing_user.identity_token,
        created_at=maybe_existing_user.created_at,
    )

    supabase_client.upsert_user(user)
    return {
        "success": True,
        "jwt_token": user.jwt_token,
        "user_id": user.user_id,
        "is_new_user": is_new_user,
    }


def apple_authenticate(user_id: str, identity_token: str) -> dict:
    """
    Authenticate with Apple code, and sign up the user if they don't exist.

    :param user_id: Apple user ID
    :param identity_token: Apple identity token
    :return: Dictionary with success status and JWT token
    """
    user = User(
        athlete_id=DEFAULT_ATHLETE_ID,
        user_id=user_id,
        identity_token=identity_token,
    )
    supabase_client.upsert_user(user)
    return {
        "success": True,
        "jwt_token": user.jwt_token,
        "user_id": user.user_id,
        "is_new_user": True,
    }
