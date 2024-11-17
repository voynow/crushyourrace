import logging
import os

from fastapi import (
    BackgroundTasks,
    Body,
    Depends,
    FastAPI,
    Form,
    HTTPException,
    Request,
)
from src import activities, auth_manager, supabase_client, webhook
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.types.user import UserRow
from src.types.webhook import StravaEvent
from src.update_pipeline import update_all_users, update_training_week

app = FastAPI()

logger = logging.getLogger("uvicorn.error")


# health check
@app.get("/health")
async def health():
    logger.info("Healthy ✅")
    return {"status": "healthy"}


@app.get("/training_week/", response_model=FullTrainingWeek)
async def training_week(user: UserRow = Depends(auth_manager.validate_user)):
    """
    Retrieve the most recent training_week row by athlete_id
    curl -X GET "http://trackflow-alb-499532887.us-east-1.elb.amazonaws.com/training_week/" \
    -H "Authorization: Bearer YOUR_JWT_TOKEN"

    :param athlete_id: The athlete_id to retrieve the training_week for
    :return: The most recent training_week row for the athlete
    """
    try:
        return supabase_client.get_training_week(user.athlete_id)
    except ValueError as e:
        logger.error(f"Error retrieving training week: {e}", exc_info=True)
        raise HTTPException(status_code=404, detail=str(e))


@app.post("/device_token/")
async def update_device_token(
    device_token: str = Body(..., embed=True),
    user: UserRow = Depends(auth_manager.validate_user),
) -> dict:
    """
    Update device token for push notifications

    :param device_token: The device token to register
    :param user: The authenticated user
    :return: Success status
    """
    try:
        supabase_client.update_user_device_token(
            athlete_id=user.athlete_id, device_token=device_token
        )
        return {"success": True}
    except Exception as e:
        logger.error(f"Failed to update device token: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/preferences/")
async def update_preferences(
    preferences: dict, user: UserRow = Depends(auth_manager.validate_user)
) -> dict:
    """
    Update user preferences

    :param preferences: Dictionary of user preferences to update
    :param user: The authenticated user
    :return: Success status
    """
    try:
        supabase_client.update_preferences(
            athlete_id=user.athlete_id, preferences=preferences
        )
        return {"success": True}
    except Exception as e:
        logger.error(f"Failed to update preferences: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/profile/")
async def get_profile(user: UserRow = Depends(auth_manager.validate_user)) -> dict:
    """
    Retrieve user profile information including Strava details

    :param user: The authenticated user
    :return: Dictionary containing profile information
    """
    try:
        athlete = auth_manager.get_strava_client(user.athlete_id).get_athlete()
        return {
            "success": True,
            "profile": {
                "firstname": athlete.firstname,
                "lastname": athlete.lastname,
                "profile": athlete.profile,
                "email": user.email,
                "preferences": user.preferences.json(),
            },
        }
    except Exception as e:
        logger.error(f"Failed to get profile: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/weekly_summaries/")
async def get_weekly_summaries(
    user: UserRow = Depends(auth_manager.validate_user),
) -> dict:
    """
    Retrieve weekly training summaries for the authenticated user

    :param user: The authenticated user
    :return: List of WeekSummary objects as JSON
    """
    try:
        strava_client = auth_manager.get_strava_client(user.athlete_id)
        weekly_summaries = activities.get_weekly_summaries(strava_client)
        return {
            "success": True,
            "weekly_summaries": [summary.json() for summary in weekly_summaries],
        }
    except Exception as e:
        logger.error(f"Failed to get weekly summaries: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/authenticate/")
async def authenticate(code: str = Form(...)) -> dict:
    """
    Authenticate with Strava code and sign up new users

    :param code: Strava authorization code from form data
    :return: Dictionary with success status, JWT token and new user flag
    """
    try:
        return auth_manager.authenticate_on_signin(code=code)
    except Exception as e:
        logger.error(f"Authentication failed: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/strava-webhook/")
async def strava_webhook(request: Request, background_tasks: BackgroundTasks) -> dict:
    """
    Handle Strava webhook events

    :param request: Webhook request from Strava
    :param background_tasks: FastAPI background tasks
    :return: Success status
    """
    event = await request.json()
    strava_event = StravaEvent(**event)
    background_tasks.add_task(webhook.maybe_process_strava_event, strava_event)
    return {"success": True}


@app.post("/onboarding/")
async def trigger_new_user_onboarding(
    user: UserRow = Depends(auth_manager.validate_user),
) -> dict:
    """
    Initialize training weeks for new user onboarding

    :param user: The authenticated user
    :return: Success status
    """
    try:
        update_training_week(user, ExeType.NEW_WEEK)
        update_training_week(user, ExeType.MID_WEEK)
        return {"success": True}
    except Exception as e:
        logger.error(f"Failed to start onboarding: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/update-all-users/")
async def update_all_users_trigger(request: Request) -> dict:
    """
    Trigger nightly updates for all users
    Protected by API key authentication
    """
    api_key = request.headers.get("x-api-key")
    if api_key != os.environ["API_KEY"]:
        raise HTTPException(status_code=403, detail="Invalid API key")

    update_all_users()
    return {"success": True}
