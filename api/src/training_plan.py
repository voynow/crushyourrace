import datetime
from typing import List, Optional

import numpy as np
from src import supabase_client
from src.constants import COACH_ROLE
from src.llm import get_completion_json
from src.types.activity import WeekSummary
from src.types.training_plan import TrainingPlan, WeekRange
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


def gen_training_plan(
    user: User, weekly_summaries: List[WeekSummary], dt: datetime.datetime
) -> TrainingPlan:
    """
    Generate a training plan for the user given training history

    :param user: User object
    :param weekly_summaries: List of WeekSummary objects
    :param dt: datetime injection, helpful for testing
    :return: TrainingPlan object
    """

    sorted_weekly_summaries = sorted(weekly_summaries, key=lambda x: x.week_start_date)
    weekly_mileages = [summary.total_distance for summary in sorted_weekly_summaries]
    last_52_weeks_mileage_stats = get_mileage_stats(weekly_mileages)
    last_16_weeks_mileage_stats = get_mileage_stats(weekly_mileages[-16:])

    # create week_ranges string for prompt
    week_ranges = "\n".join(
        str(week_range)
        for week_range in get_week_ranges_to_race(
            dt=dt, race_date=user.preferences.race_date
        )
    )

    message = f"""# Best practices for distance running training plans
1. Simple is better than complex - No need to get cute with cutbacks weeks unless the training block is very long
2. Its best to be peaking at n_weeks_until_race=6,5,4 and begin tapering at n_weeks_until_race=3. Peaking too early is bad because the athlete won't be maximally fit for the race.
3. If the athlete is behind schedule (e.g. doesn't have many weeks left) then delay the peak as needed
4. Athletes expect to be challenged - if last training block they peaked at 55 miles per week then maybe push them to peak at 60 miles per week this block

---

# Example Training Plans

## Beginner Marathon (Little to no running experience)
### Build: Weeks 1-12
- Total Volume: 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 (increase by 1 mile per week)
- Long Run: 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13 (increase by 1 mile per week)
### Peak: Weeks 13-16
- Total Volume: 26, 27, 28, 29 (hold volume at 29 miles per week)
- Long Run: 14, 15, 16, 17 (get comfortable with bigger long runs)
### Tapering: Weeks 17-18
- Total Volume: 24, 22 (decrease by 2 miles per week)
- Long Run: 12, 10 (decrease by 2 miles per week)
### Race Week: Week 19
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Intermediate Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-8
- Total Volume: 20, 22, 24, 26, 28, 30, 32, 34 (increase by 2 miles per week)
- Long Run: 10, 11, 12, 13, 14, 15, 16, 17 (increase by 1 mile per week)
### Peak: Weeks 9-13
- Total Volume: 40, 40, 40, 40 (hold volume at 40 miles per week)
- Long Run: 18, 19, 18, 20 (get comfortable with bigger long runs)
### Tapering: Weeks 14-15
- Total Volume: 36, 32 (decrease by 2 miles per week)
- Long Run: 16, 14 (decrease by 2 miles per week)
### Race Week: Week 16
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Experienced Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-6
- Total Volume: 30, 40, 45, 50, 55, 55 (push toward 55 miles per week)
- Long Run: 14, 16, 16, 18, 18, 18 (get comfortable with 18 mile long runs)
### Peak: Weeks 7-10
- Total Volume: 60, 62, 64, 60 (experiment with 60-64 miles per week)
- Long Run: 20, 20, 18, 20 (get a few 20 milers in, adding some marathon pace work interspersed with the long runs)
### Tapering: Weeks 11-12
- Total Volume: 50, 45 (decrease to more manageable volume)
- Long Run: 18, 16 (keep it chill)
### Race Week: Week 13
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## No Race Date Provided: Simply get them into shape or keep them in shape; No need to peak
### Build: Weeks 1-4
- Total Volume: 14, 16, 18, 20 (increase by 2 miles per week)
- Long Run: 7, 8, 8, 9 (increase by 1 mile per week)
### Maintenance: Weeks 5-12
- Total Volume: 20, 22, 20, 24, 20, 22, 20, 26 (trying out different volume around 20-26 miles per week)
- Long Run: 10, 12, 10, 12, 10, 12, 10, 12 (trying out different long run distances around 10-12 miles)
Note: Maintainance volume and long run distances are heavily dependent on the athlete's current fitness level.

---

{COACH_ROLE}

Your client is participating in race_distance={user.preferences.race_distance} on race_date={user.preferences.race_date} (today is {dt.date()})

Now lets take a look at how your client has been training over the past 52 weeks:

Your client's mileage stats over the past 52 weeks...
{last_52_weeks_mileage_stats}

Your client's mileage stats over the past 16 weeks...
{last_16_weeks_mileage_stats}

Given this information, now you must generate a training plan for your client over the following weeks:
{week_ranges}"""

    return get_completion_json(message=message, response_model=TrainingPlan)


def gen_training_plan_pipeline(
    user: User, weekly_summaries: List[WeekSummary], dt: datetime.datetime
) -> TrainingPlan:
    """
    Generate a training plan for the user given training history

    :param user: User object
    :param weekly_summaries: List of WeekSummary objects
    :param dt: datetime injection, helpful for testing
    :return: TrainingPlan object
    """
    training_plan = gen_training_plan(
        user=user, weekly_summaries=weekly_summaries, dt=dt
    )
    supabase_client.insert_training_plan(
        athlete_id=user.athlete_id, training_plan=training_plan
    )
    return training_plan
