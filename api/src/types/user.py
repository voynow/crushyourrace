import datetime
from enum import StrEnum
from typing import List, Optional
from zoneinfo import ZoneInfo

from pydantic import BaseModel, validator
from src import utils
from src.constants import DEFAULT_ATHLETE_ID, DEFAULT_JWT_TOKEN, DEFAULT_USER_ID
from src.types.training_week import Day, SessionType
from src.utils import datetime_now_est


class RaceDistance(StrEnum):
    FIVE_KILOMETER = "5K"
    TEN_KILOMETER = "10K"
    HALF_MARATHON = "Half Marathon"
    MARATHON = "Marathon"
    ULTRA_MARATHON = "Ultra Marathon"
    NONE = "none"


class TheoreticalTrainingSession(BaseModel):
    day: Day
    session_type: SessionType


class Preferences(BaseModel):
    race_distance: Optional[RaceDistance] = None
    race_date: Optional[datetime.date] = None
    ideal_training_week: Optional[List[TheoreticalTrainingSession]] = []

    def dict(self, *args, **kwargs):
        data = super().dict(*args, **kwargs)
        if isinstance(data["race_date"], datetime.date):
            data["race_date"] = data["race_date"].isoformat()
        return data


class User(BaseModel):
    """
    Representing an application user

    :athlete_id: athlete ID provided by Strava
    :email: Email provided by the user
    :preferences: Preferences (e.g. race distance)
    :is_premium: whether or not the user is premium

    :access_token: Strava access token
    :refresh_token: Strava refresh token
    :expires_at: Strava access token expiration date

    :jwt_token: JWT token for generic authentication
    :user_id: User ID for apple authentication

    :device_token: Device token for apple push notifications
    :identity_token: Provided by apple auth but largely unused

    :created_at: Date the user was created
    """

    athlete_id: Optional[int] = DEFAULT_ATHLETE_ID
    email: Optional[str] = None
    preferences: Optional[Preferences] = Preferences()
    is_premium: Optional[bool] = False

    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime.datetime] = None

    jwt_token: Optional[str] = DEFAULT_JWT_TOKEN
    user_id: Optional[str] = DEFAULT_USER_ID

    device_token: Optional[str] = None
    identity_token: Optional[str] = None

    created_at: datetime.datetime = datetime_now_est()
