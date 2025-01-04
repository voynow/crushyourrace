import datetime
from typing import Optional

from pydantic import BaseModel


class Activity(BaseModel):
    id: int = -1
    achievement_count: int = 0
    athlete_count: int = 0
    average_speed: float = 0.0
    comment_count: int = 0
    distance: float = 0.0
    elapsed_time: datetime.timedelta = datetime.timedelta(0)
    elev_high: Optional[float] = None
    elev_low: Optional[float] = None
    external_id: Optional[str] = None
    flagged: bool = False
    gear_id: Optional[str] = None
    has_kudoed: bool = False
    kudos_count: int = 0
    manual: bool = False
    max_speed: float = 0.0
    moving_time: datetime.timedelta = datetime.timedelta(0)
    name: str = "Empty Activity"
    private: bool = True
    start_date: datetime.datetime = datetime.datetime.min
    start_date_local: datetime.datetime = datetime.datetime.min
    timezone: str = ""
    total_elevation_gain: float = 0.0
    total_photo_count: int = 0
    trainer: bool = False
    upload_id: Optional[int] = None
    workout_type: Optional[int] = None
    utc_offset: float = 0.0
    pr_count: int = 0
    has_heartrate: bool = False
    average_heartrate: Optional[float] = None
    max_heartrate: Optional[float] = None
    average_cadence: Optional[float] = None
    average_temp: Optional[float] = None


class DailyActivity(BaseModel):
    date: datetime.date
    day_of_week: str
    week_of_year: int
    year: int
    distance_in_miles: float
    elevation_gain_in_feet: float
    moving_time_in_minutes: float
    pace_minutes_per_mile: Optional[float]
    activity_ids: list[int]
    activity_count: int


class ActivitySummary(BaseModel):
    date: str
    """Datetime formatted as 'Monday, August 13, 2024'"""

    distance_in_miles: float
    elevation_gain_in_feet: float
    pace_minutes_per_mile: Optional[float]


class WeekSummary(BaseModel):
    year: int
    week_of_year: int
    week_start_date: datetime.date
    longest_run: float
    total_distance: float

    def __str__(self):
        return f"WeekSummary(year={self.year}, week_of_year={self.week_of_year}, week_start_date={self.week_start_date}, longest_run={self.longest_run}, total_distance={self.total_distance})"

    def __repr__(self):
        return str(self)
