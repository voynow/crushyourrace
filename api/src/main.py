import logging
import os
from typing import Callable, Optional

from fastapi import (
    BackgroundTasks,
    Body,
    Depends,
    FastAPI,
    Form,
    HTTPException,
    Request,
    Response,
)
from src import activities, auth_manager, email_manager, supabase_client, utils, webhook
from src.middleware import log_and_handle_errors
from src.types.feedback import FeedbackRow
from src.types.training_plan import TrainingPlan
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.types.user import User
from src.types.webhook import StravaEvent
from src.update_pipeline import update_all_users, update_training_week

app = FastAPI()

logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("stravalib.protocol").setLevel(logging.WARNING)
logger = logging.getLogger("uvicorn.error")


@app.middleware("http")
async def middleware(request: Request, call_next: Callable) -> Response:
    return await log_and_handle_errors(request, call_next)


@app.get("/health")
@app.head("/health", include_in_schema=False)
async def health():
    return {"status": "healthy ✅"}


@app.get("/training-week/", response_model=FullTrainingWeek)
async def training_week(user: User = Depends(auth_manager.validate_user)):
    """
    Retrieve the most recent training_week row by athlete_id
    curl -X GET "http://trackflow-alb-499532887.us-east-1.elb.amazonaws.com/training_week/" \
    -H "Authorization: Bearer YOUR_JWT_TOKEN"

    :param athlete_id: The athlete_id to retrieve the training_week for
    :return: The most recent training_week row for the athlete
    """
    return supabase_client.get_training_week(user.athlete_id)


@app.post("/device-token/")
async def update_device_token(
    device_token: str = Body(..., embed=True),
    user: User = Depends(auth_manager.validate_user),
) -> dict:
    """
    Update device token for push notifications

    :param device_token: The device token to register
    :param user: The authenticated user
    :return: Success status
    """
    supabase_client.update_user_device_token(
        athlete_id=user.athlete_id, device_token=device_token
    )
    return {"success": True}


@app.post("/preferences/")
async def update_preferences(
    preferences: dict, user: User = Depends(auth_manager.validate_user)
) -> dict:
    """
    Update user preferences

    :param preferences: Dictionary of user preferences to update
    :param user: The authenticated user
    :return: Success status
    """
    supabase_client.update_preferences(
        athlete_id=user.athlete_id, preferences=preferences
    )
    return {"success": True}


@app.get("/profile/")
async def get_profile(user: User = Depends(auth_manager.validate_user)) -> dict:
    """
    Retrieve user profile information including Strava details

    :param user: The authenticated user
    :return: Dictionary containing profile information
    """
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


@app.get("/v2/profile/")
async def get_profile_v2(user: User = Depends(auth_manager.validate_user)) -> dict:
    """
    Retrieve user profile information including Strava details

    :param user: The authenticated user
    :return: Dictionary containing profile information
    """
    athlete = auth_manager.get_strava_client(user.athlete_id).get_athlete()
    return {
        "success": True,
        "profile": {
            "firstname": athlete.firstname,
            "lastname": athlete.lastname,
            "profile": athlete.profile,
            "email": user.email,
            "preferences": user.preferences.json(),
            "member_since": user.created_at.date(),
            "is_premium": user.is_premium,
        },
    }


@app.get("/weekly-summaries/")
async def get_weekly_summaries(
    user: User = Depends(auth_manager.validate_user),
) -> dict:
    """
    Retrieve weekly training summaries for the authenticated user

    :param user: The authenticated user
    :return: List of WeekSummary objects as JSON
    """
    strava_client = auth_manager.get_strava_client(user.athlete_id)
    weekly_summaries = activities.get_weekly_summaries(
        strava_client=strava_client, dt=utils.datetime_now_est()
    )
    return {
        "success": True,
        "weekly_summaries": [summary.json() for summary in weekly_summaries],
    }


@app.post("/authenticate/")
async def authenticate(
    code: Optional[str] = Form(None),
    user_id: Optional[str] = Form(None),
    identity_token: Optional[str] = Form(None),
):
    """
    Authenticate with Strava code or Apple credentials

    :param code: Strava code
    :param user_id: Apple user ID
    :param identity_token: Apple identity token
    :param email: Apple email (optional, currently/temporarily unused)
    :return: Success status
    """
    if code:
        return auth_manager.strava_authenticate(code=code)
    elif user_id and identity_token:
        return auth_manager.apple_authenticate(
            user_id=user_id, identity_token=identity_token
        )
    else:
        raise HTTPException(status_code=400, detail="Invalid request")


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


@app.post("/refresh/")
async def refresh_user_data(
    user: User = Depends(auth_manager.validate_user),
) -> dict:
    """
    Trigger new week and mid-week updates

    :param user: The authenticated user
    :return: Success status
    """
    update_training_week(user, ExeType.NEW_WEEK, dt=utils.get_last_sunday())
    update_training_week(user, ExeType.MID_WEEK, dt=utils.datetime_now_est())
    return {"success": True}


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


@app.post("/user/")
async def create_user(
    jwt_token: str = Body(...),
    code: str = Body(...),
    email: Optional[str] = Body(None),
):
    supabase_client.create_user(jwt_token=jwt_token, code=code, email=email)
    return {"success": True}


@app.get("/training-plan/", response_model=TrainingPlan)
async def get_training_plan(
    user: User = Depends(auth_manager.validate_user),
) -> TrainingPlan:
    """
    Get the training plan for a user
    """
    return supabase_client.get_training_plan(user.athlete_id)


@app.post("/email/")
async def update_email(
    email: str = Body(...),
    token: Optional[str] = Body(None),
    user_id: Optional[str] = Body(None),
) -> dict:
    """
    Update email for a user during onboarding (no auth required, instead a valid
    token or id will suffice)

    :param email: The email to update
    :param token: The token to validate the request
    :param user_id: The user ID to update
    :return: Success status
    """
    supabase_client.update_user_email(email=email, jwt_token=token, user_id=user_id)
    email_manager.send_alert_email(
        subject=f"Crush Your Race: Welcome {email}!",
        text_content=f"You have a new user {email=} attempting to signup",
    )
    return {"success": True}


@app.post("/feedback/")
async def feedback(feedback: FeedbackRow):
    supabase_client.insert_feedback(feedback=feedback)
    return {"success": True}


@app.post("/premium/")
async def update_is_premium(
    user: User = Depends(auth_manager.validate_user), premium: bool = Body(...)
):
    """
    Updated is_premium when user subscribes or cancels premium
    """
    supabase_client.update_user_premium(user.athlete_id, premium)
    return {"success": True}


@app.get("/premium/")
async def premium(user: User = Depends(auth_manager.validate_user)):
    """
    Check whether or not the user is premium
    """
    return supabase_client.is_premium(user.athlete_id)


@app.get("/free-trial/")
async def free_trial(user: User = Depends(auth_manager.validate_user)):
    """
    Check whether or not we are in the free trial period
    """
    return supabase_client.are_we_in_free_trial_period(user)
