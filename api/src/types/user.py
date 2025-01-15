import datetime
from enum import StrEnum
from typing import List, Optional

from pydantic import BaseModel
from src.types.training_week import Day, SessionType


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


class UserRow(BaseModel):
    athlete_id: Optional[int] = -1
    preferences: Optional[Preferences] = Preferences()
    email: Optional[str] = None
    created_at: datetime.datetime = datetime.datetime.now()
    user_id: Optional[str] = "default"
    is_premium: Optional[bool] = False


class UserAuthRow(BaseModel):
    athlete_id: Optional[int] = -1
    access_token: Optional[str] = None
    refresh_token: Optional[str] = None
    expires_at: Optional[datetime.datetime] = None
    jwt_token: Optional[str] = "default"
    device_token: Optional[str] = None
    user_id: Optional[str] = "default"
    identity_token: Optional[str] = None
