import datetime
import logging
import traceback

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
from src.constants import INVALID_ATHLETE_ID
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.types.user import User

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _update_training_week(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> FullTrainingWeek:
    """
    Single function to handle all training week updates

    :param user: UserRow object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: FullTrainingWeek object
    """
    strava_client = auth_manager.get_strava_client(user.athlete_id)
    daily_activity = activities.get_daily_activity(strava_client, dt=dt, num_weeks=52)

    mileage_rec = mileage_recommendation.get_or_gen_mileage_recommendation(
        user=user, daily_activity=daily_activity, exe_type=exe_type, dt=dt
    )

    return training_week.gen_full_training_week(
        user=user,
        daily_activity=daily_activity,
        mileage_rec=mileage_rec,
        exe_type=exe_type,
        dt=dt,
    )


def update_training_week(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> dict:
    """
    Full pipeline with update training week & push notification side effects

    :param user: UserRow object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: dict
    """
    training_week = _update_training_week(user=user, exe_type=exe_type, dt=dt)
    supabase_client.upsert_training_week(
        athlete_id=user.athlete_id,
        future_training_week=training_week.future_training_week,
        past_training_week=training_week.past_training_week,
    )
    return {"success": True}


def update_training_week_wrapper(
    user: User, exe_type: ExeType, dt: datetime.datetime
) -> dict:
    """
    Wrapper to handle errors in the update pipeline

    :param user: UserRow object
    :param exe_type: ExeType object
    :param dt: datetime injection, helpful for testing
    :return: dict
    """
    try:
        response = update_training_week(user, exe_type, dt)
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


def update_all_users() -> dict:
    """
    Evenings excluding Sunday: Send update to users who have not yet triggered an update today
    Sunday evening: Send new training week to all active users

    :return: dict
    """
    if utils.datetime_now_est().weekday() != 6:
        for user in supabase_client.list_users():
            if user.athlete_id == INVALID_ATHLETE_ID:
                continue
            if supabase_client.has_user_updated_today(user.athlete_id):
                continue
            update_training_week_wrapper(
                user, ExeType.MID_WEEK, dt=utils.datetime_now_est()
            )
    else:
        # all users get a new training week on Sunday night
        for user in supabase_client.list_users():
            if user.athlete_id == INVALID_ATHLETE_ID:
                continue
            update_training_week_wrapper(
                user, ExeType.NEW_WEEK, dt=utils.get_last_sunday()
            )
    return {"success": True}
