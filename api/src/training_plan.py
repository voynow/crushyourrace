import asyncio
import datetime
from typing import List, Optional

import numpy as np
from src import supabase_client
from src.constants import COACH_ROLE
from src.llm import get_completion_json
from src.prompts import TRAINING_PLAN_PROMPT, TRAINING_PLAN_SKELETON_PROMPT
from src.types.activity import WeekSummary
from src.types.training_plan import (
    TrainingPlan,
    TrainingPlanSkeleton,
    TrainingPlanWeek,
    TrainingPlanWeekGeneration,
    TrainingPlanWeekLight,
    WeekRange,
)
from src.types.user import User


def get_mileage_stats(weekly_mileages):
    """
    Returns an LLM-friendly string containing information about the athlete's
    mileage stats over the past X weeks.

    :param weekly_mileages: A list of weekly mileages.
    :return: str of LLM-friendly statistics
    """
    total_miles = round(sum(weekly_mileages), 1)
    miles_per_week = round(total_miles / len(weekly_mileages), 1)
    median_weekly_mileage = round(np.median(weekly_mileages), 1)
    seventy_five_percentile_weekly_mileage = round(
        np.percentile(weekly_mileages, 75), 1
    )
    ninety_percentile_weekly_mileage = round(np.percentile(weekly_mileages, 90), 1)

    return_str = ""
    return_str += f"Total miles: {total_miles}\n"
    return_str += f"Avg Miles per week: {miles_per_week}\n"
    return_str += f"Median weekly mileage: {median_weekly_mileage}\n"
    return_str += (
        f"75%ile of weekly mileage: {seventy_five_percentile_weekly_mileage}\n"
    )
    return_str += f"90%ile of weekly mileage: {ninety_percentile_weekly_mileage}\n"
    return_str += f"Max weekly mileage: {max(weekly_mileages)}\n"
    return return_str


def get_week_ranges_to_race(
    dt: datetime.datetime, race_date: Optional[datetime.date]
) -> List[WeekRange]:
    """
    Returns the start and end dates of every week from today to the race date.
    Weeks start on Monday and end on Sunday. If race_date is None, choose arbitrary
    date in the future for generic training plan generation purposes.

    :param race_date: The date of the race (datetime object, UTC).
    :return: A list of WeekRange objects representing each week.
    """
    today = dt.date()
    days_until_monday = (7 - today.weekday()) % 7
    start_date = today + datetime.timedelta(days=days_until_monday)

    if race_date is None:
        # create arbitrary race date 12 weeks from now
        race_date = start_date + datetime.timedelta(days=84)

    week_ranges = []

    week_ranges = []
    current_date = start_date
    week_number = 1
    while current_date <= race_date:
        end_date = min(current_date + datetime.timedelta(days=6), race_date)
        week_ranges.append(
            WeekRange(
                start_date=current_date,
                end_date=end_date,
                week_number=week_number,
                n_weeks_until_race=int((race_date - current_date).days / 7),
            )
        )
        current_date += datetime.timedelta(days=7)
        week_number += 1

    return week_ranges


async def gen_training_plan_skeleton(
    user: User,
    dt: datetime.datetime,
    week_ranges: List[WeekRange],
    last_52_weeks_mileage_stats: str,
    last_16_weeks_mileage_stats: str,
) -> TrainingPlanSkeleton:

    week_ranges_str = "\n".join(str(week_range) for week_range in week_ranges)

    message = TRAINING_PLAN_SKELETON_PROMPT.substitute(
        COACH_ROLE=COACH_ROLE,
        race_distance=user.preferences.race_distance,
        race_date=user.preferences.race_date,
        today=dt.date(),
        last_52_weeks_mileage_stats=last_52_weeks_mileage_stats,
        last_16_weeks_mileage_stats=last_16_weeks_mileage_stats,
        week_ranges=week_ranges_str,
    )

    max_attempts = 3
    for _ in range(max_attempts):
        training_plan_skeleton = await get_completion_json(
            message=message,
            response_model=TrainingPlanSkeleton,
            generation_name="gen_training_plan",
        )
        if len(training_plan_skeleton.weeks) == len(week_ranges):
            return training_plan_skeleton

    raise ValueError(
        f"Failed to generate a valid training plan skeleton after {max_attempts} attempts. "
        f"Expected {len(week_ranges)} weeks, but got {len(training_plan_skeleton.weeks)} in the final attempt."
    )


async def gen_training_plan_week(
    user: User,
    dt: datetime.datetime,
    last_52_weeks_mileage_stats: str,
    last_16_weeks_mileage_stats: str,
    training_plan_week_light: TrainingPlanWeekLight,
    week_range: WeekRange,
    training_block_length: int,
) -> TrainingPlanWeek:
    """
    Generate a training plan week asynchronously.

    :param user: User object
    :param dt: Current datetime
    :param last_52_weeks_mileage_stats: Mileage stats over last 52 weeks
    :param last_16_weeks_mileage_stats: Mileage stats over last 16 weeks
    :param training_plan_week_light: Lightweight training plan week info
    :param week_range: WeekRange object containing week details
    :param training_block_length: Total number of weeks in training block
    :return: TrainingPlanWeek object
    """
    message = TRAINING_PLAN_PROMPT.substitute(
        COACH_ROLE=COACH_ROLE,
        race_distance=user.preferences.race_distance,
        race_date=user.preferences.race_date,
        today=dt.date(),
        last_52_weeks_mileage_stats=last_52_weeks_mileage_stats,
        last_16_weeks_mileage_stats=last_16_weeks_mileage_stats,
        training_plan_week_light=training_plan_week_light,
        training_block_length=training_block_length,
    )
    training_plan_week_generation: TrainingPlanWeekGeneration = (
        await get_completion_json(
            message=message,
            model="gpt-4o-mini",
            response_model=TrainingPlanWeekGeneration,
            generation_name="gen_training_plan_week",
        )
    )
    return TrainingPlanWeek(
        week_start_date=week_range.start_date,
        week_number=week_range.week_number,
        n_weeks_until_race=week_range.n_weeks_until_race,
        week_type=training_plan_week_generation.week_type,
        total_distance=training_plan_week_light.volume,
        long_run_distance=training_plan_week_light.long_run,
        notes=training_plan_week_generation.notes,
    )


async def gen_training_plan(
    user: User, weekly_summaries: List[WeekSummary], dt: datetime.datetime
) -> TrainingPlan:
    """
    Generate a training plan for the user given training history.

    :param user: User object
    :param weekly_summaries: List of WeekSummary objects
    :param dt: Current datetime, useful for testing
    :return: TrainingPlan object
    """
    sorted_weekly_summaries: List[WeekSummary] = sorted(
        weekly_summaries, key=lambda x: x.week_start_date
    )
    weekly_mileages: List[float] = [
        summary.total_distance for summary in sorted_weekly_summaries
    ]
    last_52_weeks_mileage_stats: str = get_mileage_stats(weekly_mileages)
    last_16_weeks_mileage_stats: str = get_mileage_stats(weekly_mileages[-16:])

    week_ranges: List[WeekRange] = get_week_ranges_to_race(
        dt=dt, race_date=user.preferences.race_date
    )

    training_plan_skeleton: TrainingPlanSkeleton = await gen_training_plan_skeleton(
        user=user,
        dt=dt,
        week_ranges=week_ranges,
        last_52_weeks_mileage_stats=last_52_weeks_mileage_stats,
        last_16_weeks_mileage_stats=last_16_weeks_mileage_stats,
    )

    tasks = [
        gen_training_plan_week(
            user=user,
            dt=dt,
            last_52_weeks_mileage_stats=last_52_weeks_mileage_stats,
            last_16_weeks_mileage_stats=last_16_weeks_mileage_stats,
            training_plan_week_light=training_plan_week_light,
            week_range=week_range,
            training_block_length=len(week_ranges),
        )
        for week_range, training_plan_week_light in zip(
            week_ranges, training_plan_skeleton.weeks
        )
    ]
    training_plan_weeks: List[TrainingPlanWeek] = await asyncio.gather(*tasks)

    return TrainingPlan(training_plan_weeks=training_plan_weeks)


async def gen_training_plan_pipeline(
    user: User, weekly_summaries: List[WeekSummary], dt: datetime.datetime
) -> TrainingPlan:
    """
    Generate a training plan for the user given training history

    :param user: User object
    :param weekly_summaries: List of WeekSummary objects
    :param dt: datetime injection, helpful for testing
    :return: TrainingPlan object
    """
    training_plan = await gen_training_plan(
        user=user, weekly_summaries=weekly_summaries, dt=dt
    )
    supabase_client.insert_training_plan(
        athlete_id=user.athlete_id, training_plan=training_plan
    )
    return training_plan
