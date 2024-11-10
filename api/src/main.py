import logging

from fastapi import Body, Depends, FastAPI, HTTPException
from src import activities, auth_manager, supabase_client
from src.types.training_week import TrainingWeek
from src.types.user import UserRow

app = FastAPI()

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


@app.get("/training_week/", response_model=TrainingWeek)
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
            "weekly_summaries": [
                summary.json() for summary in weekly_summaries
            ],
        }
    except Exception as e:
        logger.error(f"Failed to get weekly summaries: {e}", exc_info=True)
        raise HTTPException(status_code=400, detail=str(e))
