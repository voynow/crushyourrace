from pydantic import BaseModel
from math import floor


class Speed(BaseModel):
    min: int
    sec: int


class Split(BaseModel):
    distance_in_miles: float
    average_speed_per_mile: Speed
    elevation_gain_in_feet: float
    average_heartrate: float


class DetailedActivity(BaseModel):
    distance_in_miles: float
    average_speed_per_mile: Speed
    elevation_gain_in_feet: float
    average_heartrate: float
    splits: list[Split]


def compute_activity_metrics(activity):
    moving_time_in_minutes = activity.moving_time.total_seconds() / 60
    distance_in_miles = activity.distance / 1609.34
    average_speed_minutes_per_mile = (moving_time_in_minutes / distance_in_miles).magnitude

    # compatibility for Split and DetailedActivity elevation gain
    if hasattr(activity, "total_elevation_gain"):
        elevation_gain_in_feet = activity.total_elevation_gain * 3.28084
    else:
        elevation_gain_in_feet = activity.elevation_difference * 3.28084

    average_speed_per_mile = Speed(
        min=floor(average_speed_minutes_per_mile),
        sec=floor((average_speed_minutes_per_mile - floor(average_speed_minutes_per_mile)) * 60),
    )

    return {
        "distance_in_miles": round(distance_in_miles, 2),
        "average_speed_per_mile": average_speed_per_mile,
        "elevation_gain_in_feet": round(elevation_gain_in_feet, 2),
        "average_heartrate": round(activity.average_heartrate, 2),
    }


def get_detailed_activity(strava_client, activity_id):
    activity = strava_client.get_activity(activity_id)
    splits = [
        Split(**compute_activity_metrics(split)) for split in activity.splits_standard
    ]
    return DetailedActivity(**compute_activity_metrics(activity), splits=splits)
