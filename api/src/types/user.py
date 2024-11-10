from datetime import datetime
from enum import StrEnum
from typing import List, Optional

from pydantic import BaseModel
from src.types.training_week import Day, SessionType


class RaceDistance(StrEnum):
    FIVE_KILOMETER = "5k"
    TEN_KILOMETER = "10k"
    HALF_MARATHON = "half marathon"
    MARATHON = "marathon"
    ULTRA = "ultra marathon"
    NONE = "none"


class TheoreticalTrainingSession(BaseModel):
    day: Day
    session_type: SessionType


class Preferences(BaseModel):
    race_distance: Optional[RaceDistance] = None
    ideal_training_week: Optional[List[TheoreticalTrainingSession]] = []


class UserRow(BaseModel):
    athlete_id: int
    preferences: Optional[Preferences] = Preferences()
    email: Optional[str] = None
    created_at: datetime = datetime.now()


class UserAuthRow(BaseModel):
    athlete_id: int
    access_token: str
    refresh_token: str
    expires_at: datetime
    jwt_token: str
    device_token: Optional[str] = None