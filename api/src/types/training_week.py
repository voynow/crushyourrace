from enum import StrEnum
from typing import List

from pydantic import BaseModel, Field
from src.types.activity import DailyActivity


class Day(StrEnum):
    MON = "Mon"
    TUES = "Tues"
    WED = "Wed"
    THURS = "Thurs"
    FRI = "Fri"
    SAT = "Sat"
    SUN = "Sun"


class PseudoTrainingDay(BaseModel):
    day: Day
    number_of_miles: float


class PseudoTrainingWeek(BaseModel):
    days: List[PseudoTrainingDay]

    @property
    def total_mileage(self) -> float:
        return sum(day.number_of_miles for day in self.days)


class SessionType(StrEnum):
    EASY = "easy run"
    LONG = "long run"
    SPEED = "speed workout"
    REST = "rest day"


class TrainingSession(BaseModel):
    day: Day
    session_type: SessionType
    distance: float = Field(
        description="Distance in miles, rounded to the nearest 1/2 mile"
    )
    notes: str = Field(
        description="Detailed yet concise notes about the session from the coach's perspective"
    )


class TrainingWeek(BaseModel):
    sessions: List[TrainingSession] = Field(default_factory=list)

    @property
    def total_mileage(self) -> float:
        return sum(session.distance for session in self.sessions)


class EnrichedActivity(BaseModel):
    activity: DailyActivity
    coaches_notes: str


class FullTrainingWeek(BaseModel):
    past_training_week: List[EnrichedActivity]
    future_training_week: TrainingWeek
