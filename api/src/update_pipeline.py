import datetime
import logging
import traceback
from typing import Optional

from src import (
    activities,
    apn,
    auth_manager,
    email_manager,
    mileage_recommendation,
    supabase_client,
    training_week,
    utils,
)
from src.constants import DEFAULT_ATHLETE_ID
from src.types.mileage_recommendation import MileageRecommendation
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.types.user import User

logger = logging.getLogger()
logger.setLevel(logging.INFO)


async def _update_training_week(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> FullTrainingWeek:
    """
    Single function to handle all training week updates

    :param user: User object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: FullTrainingWeek object
    """
    strava_client = auth_manager.get_strava_client(user.athlete_id)
    daily_activity = activities.get_daily_activity(strava_client, dt=dt, num_weeks=52)

    mileage_rec = await mileage_recommendation.get_or_gen_mileage_recommendation(
        user=user, daily_activity=daily_activity, exe_type=exe_type, dt=dt
    )

    return await training_week.gen_full_training_week(
        user=user,
        daily_activity=daily_activity,
        mileage_rec=mileage_rec,
        exe_type=exe_type,
        dt=dt,
    )


async def update_training_week(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> dict:
    """
    Full pipeline with update training week

    :param user: User object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: dict
    """
    training_week = await _update_training_week(user=user, exe_type=exe_type, dt=dt)
    supabase_client.upsert_training_week(
        athlete_id=user.athlete_id,
        future_training_week=training_week.future_training_week,
        past_training_week=training_week.past_training_week,
    )
    return {"success": True}


async def update_training_week_wrapper(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> dict:
    """
    Wrapper to handle errors in the update pipeline

    :param user: User object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: dict
    """
    try:
        response = await update_training_week(user, exe_type, dt)
        apn.send_push_notif_wrapper(user)
        return response
    except Exception as e:
        error_message = f"Error updating training week for user {user.athlete_id}: {e}\n{traceback.format_exc()}"
        logger.error(error_message)
        email_manager.send_alert_email(
            subject="Crush Your Race Update Pipeline Error 😵‍💫",
            text_content=error_message,
        )
        return {"success": False, "error": error_message}


async def update_all_users(dt: Optional[datetime.datetime] = None) -> dict:
    """
    Evenings excluding Sunday: Send update to users who have not yet triggered an update today
    Sunday evening: Send new training week to all active users

    :return: dict
    """

    if dt is None:
        dt = utils.datetime_now_est()

    if dt.weekday() != 6:
        for user in supabase_client.list_users():
            if user.athlete_id == DEFAULT_ATHLETE_ID:
                continue
            if supabase_client.has_user_updated_today(user.athlete_id):
                continue
            await update_training_week_wrapper(user, ExeType.MID_WEEK, dt=dt)
    else:
        # all users get a new training week on Sunday night
        for user in supabase_client.list_users():
            if user.athlete_id == DEFAULT_ATHLETE_ID:
                continue
            await update_training_week_wrapper(
                user, ExeType.NEW_WEEK, dt=utils.get_last_sunday()
            )
    return {"success": True}


async def refresh_user_data(
    user: User, dt: datetime.datetime = utils.datetime_now_est()
) -> dict:
    """
    Refresh user data

    :param user: User object
    :param dt: datetime injection, helpful for testing
    :return: dict
    """
    strava_client = auth_manager.get_strava_client(user.athlete_id)
    daily_activity = activities.get_daily_activity(
        strava_client, dt=utils.get_last_sunday(dt), num_weeks=52
    )

    await mileage_recommendation.create_new_mileage_recommendation(
        user=user,
        daily_activity=daily_activity,
        dt=utils.get_last_sunday(dt),
        override_timedelta=True,
    )

    mileage_recommendation_row = supabase_client.get_mileage_recommendation(
        athlete_id=user.athlete_id, dt=dt
    )
    mileage_rec = MileageRecommendation(
        thoughts=mileage_recommendation_row.thoughts,
        total_volume=mileage_recommendation_row.total_volume,
        long_run=mileage_recommendation_row.long_run,
    )

    daily_activity = activities.get_daily_activity(strava_client, dt=dt, num_weeks=3)

    training_week_obj = await training_week.gen_full_training_week(
        user=user,
        daily_activity=daily_activity,
        mileage_rec=mileage_rec,
        exe_type=ExeType.MID_WEEK,
        dt=dt,
    )

    supabase_client.upsert_training_week(
        athlete_id=user.athlete_id,
        future_training_week=training_week_obj.future_training_week,
        past_training_week=training_week_obj.past_training_week,
    )
    return {"success": True}
