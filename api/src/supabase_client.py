import datetime
import logging
import os
from typing import List, Optional
from uuid import uuid4

import orjson
from dotenv import load_dotenv
from src import auth_manager, supabase_helpers
from src.constants import FREE_TRIAL_DAYS
from src.types.feedback import FeedbackRow
from src.types.mileage_recommendation import (
    MileageRecommendationRow,
)
from src.types.training_plan import TrainingPlan, TrainingPlanWeekRow
from src.types.training_week import (
    EnrichedActivity,
    FullTrainingWeek,
    TrainingSession,
    TrainingWeek,
)
from src.types.user import Preferences, UserAuthRow, UserRow
from src.utils import datetime_now_est
from supabase import Client, create_client

load_dotenv()

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def init() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    return create_client(url, key)


client = init()


def get_device_token(athlete_id: int) -> Optional[str]:
    """
    Get the device token for a user in the database.

    :param athlete_id: The athlete's ID
    :return: The device token for the user, or None if the user does not exist
    """
    try:
        user_auth = get_user_auth(athlete_id)
        return user_auth.device_token
    except ValueError:
        return None


def get_user(athlete_id: int) -> UserRow:
    """
    Get a user by athlete_id

    :param athlete_id: int
    :return: UserRow
    """
    table = client.table("user")
    response = table.select("*").eq("athlete_id", athlete_id).execute()

    if not response.data:
        raise ValueError(f"Could not find user with {athlete_id=}")

    return UserRow(**response.data[0])


def list_users() -> list[UserRow]:
    """
    List all users in the user_auth table

    :return: list of UserAuthRow
    """
    table = client.table("user")
    response = table.select("*").execute()

    return [UserRow(**row) for row in response.data]


def list_user_auths() -> list[UserAuthRow]:
    """
    List all user_auths in the user_auth table

    :return: list of UserAuthRow
    """
    table = client.table("user_auth")
    response = table.select("*").execute()
    return [UserAuthRow(**row) for row in response.data]


def list_mileage_recommendations() -> list[MileageRecommendationRow]:
    """
    List all mileage_recommendations in the mileage_recommendation table

    :return: list of MileageRecommendationRow
    """
    table = client.table(supabase_helpers.get_mileage_recommendation_table_name())
    response = table.select("*").execute()
    return [MileageRecommendationRow(**row) for row in response.data]


def get_user_auth(athlete_id: int) -> UserAuthRow:
    """
    Get user_auth row by athlete_id

    :param athlete_id: int
    :return: APIResponse
    """
    table = client.table("user_auth")
    response = table.select("*").eq("athlete_id", athlete_id).execute()

    if not response.data:
        raise ValueError(f"Cound not find user_auth row with {athlete_id=}")

    return UserAuthRow(**response.data[0])


def get_training_week(athlete_id: int) -> FullTrainingWeek:
    """
    Get the most recent training_week row by athlete_id.

    :param athlete_id: int
    :return: FullTrainingWeek
    """
    table = client.table(supabase_helpers.get_training_week_table_name())
    response = (
        table.select("future_training_week, past_training_week")
        .eq("athlete_id", athlete_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )

    if not response.data:
        raise ValueError(
            f"Could not find training_week row for athlete_id {athlete_id}"
        )

    try:
        future_json_data = orjson.loads(response.data[0]["future_training_week"])
        past_json_data = orjson.loads(response.data[0]["past_training_week"])

        # temp requirement to remove legacy moderate run
        future_json_data_cleansed = []
        for session in future_json_data:
            if session["session_type"] == "moderate run":
                session["session_type"] = "easy run"
            future_json_data_cleansed.append(session)

        return FullTrainingWeek(
            past_training_week=[EnrichedActivity(**obj) for obj in past_json_data],
            future_training_week=TrainingWeek(
                sessions=[
                    TrainingSession(**session) for session in future_json_data_cleansed
                ]
            ),
        )
    except IndexError:
        raise ValueError(
            f"Could not find training_week row for athlete_id {athlete_id}"
        )


def upsert_user_auth(user_auth_row: UserAuthRow) -> None:
    """
    Convert UserAuthRow to a dictionary, ensure json serializable expires_at,
    and upsert into user_auth table handling duplicates on athlete_id and user_id

    :param user_auth_row: A dictionary representation of UserAuthRow
    """
    row_data = user_auth_row.dict()
    if isinstance(row_data["expires_at"], datetime.datetime):
        row_data["expires_at"] = row_data["expires_at"].isoformat()

    table = client.table("user_auth")
    table.upsert(
        row_data, on_conflict="athlete_id,user_id", returning="minimal"
    ).execute()


def update_user_device_token(athlete_id: str, device_token: str) -> None:
    """
    Update the device token for a user in the database.

    :param athlete_id: The athlete's ID
    :param device_token: The device token for push notifications
    """
    client.table("user_auth").update({"device_token": device_token}).eq(
        "athlete_id", athlete_id
    ).execute()


def update_preferences(athlete_id: int, preferences: dict):
    """
    Update user's preferences

    :param athlete_id: The ID of the athlete
    :param preferences: A Preferences object as a dictionary
    """
    try:
        Preferences(**preferences)
    except Exception as e:
        raise ValueError("Invalid preferences") from e

    table = client.table("user")
    table.update({"preferences": preferences}).eq("athlete_id", athlete_id).execute()


def upsert_user(user_row: UserRow):
    """
    Upsert a row into the user table

    :param user_row: An instance of UserRow
    """
    row_data = user_row.dict()
    if isinstance(row_data["created_at"], datetime.datetime):
        row_data["created_at"] = row_data["created_at"].isoformat()

    table = client.table("user")
    table.upsert(row_data, on_conflict="athlete_id,user_id").execute()


def does_user_exist(athlete_id: Optional[int], user_id: Optional[str]) -> bool:
    """
    Check if a user exists in the user table

    :param athlete_id: The ID of the athlete
    :param user_id: The ID of the user
    :return: True if the user exists, False otherwise
    """
    table = client.table("user")
    if athlete_id is None:
        response = table.select("*").eq("user_id", user_id).execute()
    else:
        response = table.select("*").eq("athlete_id", athlete_id).execute()
    return bool(response.data)


def upsert_training_week(
    athlete_id: int,
    future_training_week: TrainingWeek,
    past_training_week: List[EnrichedActivity],
):
    """
    Upsert a row into the training_week table

    :param athlete_id: The athlete's ID
    :param future_training_week: Training week data for future sessions
    :param past_training_week: List of daily metrics from past training
    """
    future_sessions = [session.dict() for session in future_training_week.sessions]
    past_sessions = [obj.dict() for obj in past_training_week]
    row_data = {
        "athlete_id": athlete_id,
        "future_training_week": orjson.dumps(future_sessions).decode("utf-8"),
        "past_training_week": orjson.dumps(past_sessions).decode("utf-8"),
    }
    table = client.table(supabase_helpers.get_training_week_table_name())
    table.upsert(row_data).execute()


def has_user_updated_today(athlete_id: int) -> bool:
    """
    Check if the user has received an update today. Where "today" is defined as
    within the past 23 hours and 30 minutes (to account for any delays in
    yesterday's evening update).

    :param athlete_id: The ID of the athlete
    :return: True if the user has received an update today, False otherwise
    """
    table = client.table(supabase_helpers.get_training_week_table_name())
    response = (
        table.select("*")
        .eq("athlete_id", athlete_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )

    if not response.data:
        return False

    # "Has this user posted an activity in the last 23 hours and 30 minutes?"
    time_diff = datetime.datetime.now(
        datetime.timezone.utc
    ) - datetime.datetime.fromisoformat(response.data[0]["created_at"])
    return time_diff < datetime.timedelta(hours=23, minutes=30)


def insert_mileage_recommendation(mileage_recommendation_row: MileageRecommendationRow):
    """
    Insert a row into the mileage_recommendations table

    :param mileage_recommendation_row: A MileageRecommendationRow object
    """
    table = client.table(supabase_helpers.get_mileage_recommendation_table_name())
    table.insert(mileage_recommendation_row.dict()).execute()


def get_mileage_recommendation(
    athlete_id: int, dt: datetime.datetime
) -> MileageRecommendationRow:
    """
    Get the most recent mileage recommendation for the given year and week of year

    :param athlete_id: The ID of the athlete
    :param dt: The datetime of the recommendation
    :return: A MileageRecommendation object
    """
    table = client.table(supabase_helpers.get_mileage_recommendation_table_name())
    week_of_year = dt.isocalendar().week
    year = dt.isocalendar().year
    response = (
        table.select("*")
        .eq("athlete_id", athlete_id)
        .eq("year", year)
        .eq("week_of_year", week_of_year)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )

    if not response.data:
        raise ValueError(
            f"Could not find mileage recommendation for {athlete_id=}, year={year}, week={week_of_year}"
        )
    return MileageRecommendationRow(**response.data[0])


def insert_training_plan(athlete_id: int, training_plan: TrainingPlan):
    """
    Insert a training plan into the training_plan table

    :param athlete_id: The ID of the athlete
    :param training_plan: A TrainingPlan object
    """
    plan_id = str(uuid4())
    table = client.table(supabase_helpers.get_training_plan_table_name())
    for week in training_plan.training_plan_weeks:
        row = {"athlete_id": athlete_id, "plan_id": plan_id, **week.dict()}
        try:
            TrainingPlanWeekRow(**row)
        except Exception as e:
            raise ValueError(f"Invalid training plan week: {row=}, {e=}")
        table.insert(row).execute()


def get_training_plan(athlete_id: int) -> TrainingPlan:
    """
    Get the most recent training plan for a specific athlete.
    Since new training plan rows are added weekly, we need to get the latest set
    based on created_at timestamp.

    :param athlete_id: The ID of the athlete
    :return: A TrainingPlan object containing the most recent set of training weeks
    """
    table = client.table(supabase_helpers.get_training_plan_table_name())

    # First get the most recent created_at timestamp for this athlete
    latest_timestamp = (
        table.select("plan_id")
        .eq("athlete_id", athlete_id)
        .order("created_at", desc=True)
        .limit(1)
        .execute()
    )

    if not latest_timestamp.data:
        logger.error(f"Could not find training plan for athlete_id {athlete_id}")
        return TrainingPlan()

    response = (
        table.select("*")
        .eq("athlete_id", athlete_id)
        .eq("plan_id", latest_timestamp.data[0]["plan_id"])
        .order("week_number")
        .execute()
    )

    training_weeks = [TrainingPlanWeekRow(**row) for row in response.data]
    return TrainingPlan(training_plan_weeks=training_weeks)


def update_user_email(
    email: str, jwt_token: Optional[str] = None, user_id: Optional[str] = None
):
    """
    Update user email

    :param email: The email to update
    :param jwt_token: Optional JWT token for authenticated users
    :param user_id: Optional user_id for new signups
    """
    table = client.table("user")

    if jwt_token:
        athlete_id = auth_manager.decode_jwt(jwt_token, verify_exp=True)
        table.update({"email": email}).eq("athlete_id", athlete_id).execute()
    elif user_id:
        table.update({"email": email}).eq("user_id", user_id).execute()
    else:
        raise ValueError("Either jwt_token or user_id must be provided")


def insert_feedback(feedback: FeedbackRow) -> None:
    """
    Insert a feedback row into the feedback table

    :param feedback: A FeedbackRow object
    :return: None
    """
    table = client.table(supabase_helpers.get_feedback_table_name())
    table.insert(feedback.dict()).execute()


def update_user_premium(athlete_id: int, is_premium: bool) -> None:
    """
    Update user premium status

    :param athlete_id: The ID of the athlete
    :param is_premium: The premium status to update
    """
    table = client.table("user")
    table.update({"is_premium": is_premium}).eq("athlete_id", athlete_id).execute()


def show_paywall(user: UserRow) -> bool:
    """
    If free trial is not over, return False (don't show paywall)
    Else return False if is_premium, True otherwise

    :param user: A UserRow object
    :return: True if the user should see the paywall, False otherwise
    """
    start_dt = user.created_at
    end_dt = start_dt + datetime.timedelta(days=FREE_TRIAL_DAYS)
    if end_dt > datetime_now_est():
        return False
    else:
        return not user.is_premium
