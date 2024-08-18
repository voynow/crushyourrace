import os
from datetime import datetime

from stravalib.client import Client

from src.activities import (
    get_activities_df,
    get_activity_summaries,
    get_day_of_week_summaries,
    get_weekly_summaries,
)
from src.auth_manager import get_strava_client
from src.constants import COACH_ROLE
from src.email_manager import (
    send_email,
    training_week_to_html,
    training_week_update_to_html,
)
from src.supabase_client import (
    get_training_week_with_coaching,
    upsert_training_week_update,
    upsert_training_week_with_coaching,
)
from src.training_week import generate_training_week
from src.training_week_update import get_updated_training_week
from src.types.mid_week_analysis import MidWeekAnalysis


def run_gen_training_week_process(
    strava_client: Client, sysmsg_base: str, athlete_id: str
):
    activities_df = get_activities_df(strava_client)
    day_of_week_summaries = get_day_of_week_summaries(activities_df)
    weekly_summaries = get_weekly_summaries(activities_df)
    training_week_with_coaching = generate_training_week(
        sysmsg_base=sysmsg_base,
        weekly_summaries=weekly_summaries,
        day_of_week_summaries=day_of_week_summaries,
    )

    upsert_training_week_with_coaching(
        athlete_id=athlete_id, training_week_with_coaching=training_week_with_coaching
    )
    send_email(
        subject="Training Schedule Just Dropped 🏃",
        html_content=training_week_to_html(training_week_with_coaching),
    )


def run_update_training_week_process(
    strava_client: Client, sysmsg_base: str, athlete_id: str
):
    training_week_with_coaching = get_training_week_with_coaching(athlete_id)
    current_weeks_activity_summaries = get_activity_summaries(
        strava_client, num_weeks=1
    )
    mid_week_analysis = MidWeekAnalysis(
        activities=current_weeks_activity_summaries,
        training_week=training_week_with_coaching.training_week,
    )
    training_week_update_with_planning = get_updated_training_week(
        sysmsg_base=sysmsg_base, mid_week_analysis=mid_week_analysis
    )

    upsert_training_week_update(
        athlete_id=athlete_id,
        mid_week_analysis=mid_week_analysis,
        training_week_update_with_planning=training_week_update_with_planning,
    )
    send_email(
        subject="Training Schedule Update 🏃",
        html_content=training_week_update_to_html(
            mid_week_analysis=mid_week_analysis,
            training_week_update_with_planning=training_week_update_with_planning,
        ),
    )


def lambda_handler(event, context):
    client_preferences = "A) Training for a marathon B) This will be my second marathon C) Prefer workouts on Wednesdays and long runs on Saturdays"
    sysmsg_base = f"{COACH_ROLE}\nYour client has included the following preferences: {client_preferences}\n"

    # activities setup
    athlete_id = os.environ["JAMIES_ATHLETE_ID"]
    strava_client = get_strava_client(athlete_id)

    # weekday 6 is Sunday
    if datetime.now().weekday() == 6:
        run_gen_training_week_process(strava_client, sysmsg_base, athlete_id)
    else:
        run_update_training_week_process(strava_client, sysmsg_base, athlete_id)
