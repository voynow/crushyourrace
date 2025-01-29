from math import floor

from src.constants import FEET_PER_METER, METERS_PER_MILE
from src.types.detailed_activity import DetailedActivity, Speed, Split


def compute_activity_metrics(activity):

    moving_time_in_minutes = activity.moving_time.total_seconds() / 60
    distance_in_miles = activity.distance / METERS_PER_MILE
    average_speed_min_per_mile = (moving_time_in_minutes / distance_in_miles).magnitude

    # compatibility for Split and DetailedActivity elevation gain
    if hasattr(activity, "total_elevation_gain"):
        elevation_gain_in_feet = activity.total_elevation_gain * FEET_PER_METER
    elif hasattr(activity, "elevation_difference"):
        elevation_gain_in_feet = activity.elevation_difference * FEET_PER_METER
    else:
        elevation_gain_in_feet = 0

    minute_remainder = average_speed_min_per_mile - floor(average_speed_min_per_mile)
    average_speed_per_mile = Speed(
        min=floor(average_speed_min_per_mile),
        sec=floor(minute_remainder * 60),
    )

    return {
        "distance_in_miles": round(distance_in_miles, 2),
        "average_speed_per_mile": average_speed_per_mile,
        "elevation_gain_in_feet": (
            round(elevation_gain_in_feet, 2) if elevation_gain_in_feet != 0 else None
        ),
        "average_heartrate": (
            round(activity.average_heartrate, 2)
            if activity.average_heartrate is not None
            else None
        ),
    }


def get_detailed_activity(strava_client, activity_id):
    """
    Get detailed activity metrics

    :param strava_client: Strava client
    :param activity_id: Strava activity ID
    :return: DetailedActivity object
    """
    activity = strava_client.get_activity(activity_id)

    if activity.splits_standard is None:
        return DetailedActivity(**compute_activity_metrics(activity))

    splits = [
        Split(**compute_activity_metrics(split)) for split in activity.splits_standard
    ]
    return DetailedActivity(**compute_activity_metrics(activity), splits=splits)
