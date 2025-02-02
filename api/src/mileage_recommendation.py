import datetime
import logging
from typing import List

from src import activities, supabase_client
from src.training_plan import gen_training_plan_pipeline
from src.types.activity import DailyActivity
from src.types.mileage_recommendation import (
    MileageRecommendation,
    MileageRecommendationRow,
)
from src.types.update_pipeline import ExeType
from src.types.user import User

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


async def gen_mileage_rec_wrapper(
    user: User, daily_activity: List[DailyActivity], dt: datetime.datetime
) -> MileageRecommendation:
    """
    Abstraction for mileage rec generation, either pulled from training plan
    generation or generated directly from weekly summaries

    :param user: User object
    :param daily_activity: List of DailyActivity objects
    :param dt: datetime injection, helpful for testing
    :return: MileageRecommendation used to generate training week
    """
    if dt.weekday() != 6:
        raise ValueError(
            "Mileage recommendation can only be generated on Sunday (night) when the week is complete"
        )

    weekly_summaries = activities.get_weekly_summaries(daily_activity=daily_activity)
    training_plan = await gen_training_plan_pipeline(
        user=user, weekly_summaries=weekly_summaries, dt=dt
    )
    next_week_plan = training_plan.training_plan_weeks[0]
    return MileageRecommendation(
        thoughts=next_week_plan.notes,
        total_volume=next_week_plan.total_distance,
        long_run=next_week_plan.long_run_distance,
    )


async def create_new_mileage_recommendation(
    user: User,
    daily_activity: List[DailyActivity],
    dt: datetime.datetime,
    override_timedelta: bool = False,
) -> MileageRecommendation:
    """
    Creates a new mileage recommendation for the next week

    :param user: user entity
    :param daily_activity: list of daily activity data
    :param dt: datetime injection, helpful for testing
    :return: mileage recommendation entity
    """
    mileage_recommendation = await gen_mileage_rec_wrapper(
        user=user, daily_activity=daily_activity, dt=dt
    )

    # hack for refresh user data route
    if override_timedelta:
        week_of_date = dt
    else:
        week_of_date = dt + datetime.timedelta(days=1)

    week_of_year = week_of_date.isocalendar().week
    year = week_of_date.isocalendar().year
    supabase_client.insert_mileage_recommendation(
        MileageRecommendationRow(
            week_of_year=week_of_year,
            year=year,
            thoughts=mileage_recommendation.thoughts,
            total_volume=mileage_recommendation.total_volume,
            long_run=mileage_recommendation.long_run,
            athlete_id=user.athlete_id,
        )
    )
    return mileage_recommendation


async def get_or_gen_mileage_recommendation(
    user: User,
    daily_activity: List[DailyActivity],
    exe_type: ExeType,
    dt: datetime,
) -> MileageRecommendation:
    """
    Executes mileage rec strategy depending on exe type

    :param user: user entity
    :param daily_activity: list of daily activity data
    :param exe_type: new week or mid week
    :param dt: datetime injection, helpful for testing
    :return: mileage recommendation entity
    """
    if exe_type == ExeType.NEW_WEEK:
        return await create_new_mileage_recommendation(
            user=user, daily_activity=daily_activity, dt=dt
        )
    else:
        mileage_recommendation_row = supabase_client.get_mileage_recommendation(
            athlete_id=user.athlete_id, dt=dt
        )
        return MileageRecommendation(
            thoughts=mileage_recommendation_row.thoughts,
            total_volume=mileage_recommendation_row.total_volume,
            long_run=mileage_recommendation_row.long_run,
        )
