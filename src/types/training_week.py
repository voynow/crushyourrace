from enum import StrEnum
from typing import Dict, List

from pydantic import BaseModel, Field


class Day(StrEnum):
    MON = "mon"
    TUES = "tues"
    WED = "wed"
    THURS = "thurs"
    FRI = "fri"
    SAT = "sat"
    SUN = "sun"


class SessionType(StrEnum):
    EASY = "easy run"
    LONG = "long run"
    SPEED = "speed workout"
    REST = "rest day"
    MODERATE = "moderate run"


class TrainingSession(BaseModel):
    day: Day
    session_type: SessionType
    distance: float = Field(description="Distance in miles")
    notes: str = Field(
        description="Concise notes about the session, e.g. '2x2mi @ 10k pace' or 'easy pace'"
    )

    def __str__(self):
        return f"TrainingSession(session_type={self.session_type}, distance={self.distance}, weekly_mileage_cumulative={self.weekly_mileage_cumulative}, notes={self.notes})"


class TrainingWeekWithPlanning(BaseModel):
    planning: str = Field(
        description="Draft a plan (used internally) to aid in training week generation. You must adhere to the weekly mileage target and long run range. Do required math (step by step out loud) to plan the week successfully. Distribute volume and intensity evenly throughout the week. If you end up exceeding the weekly mileage target, adjust one of the easy runs to be shorter."
    )
    training_week: List[TrainingSession] = Field(
        description="Unordered collection of REMAINING training sessions for the week"
    )

    @property
    def total_weekly_mileage(self) -> float:
        return sum(session.distance for session in self.training_week)
    
    def __str__(self):
        return f"TrainingWeekWithPlanning(planning={self.planning}, training_week={self.training_week})"
    
    def __repr__(self):
        return self.__str__()


class TrainingWeekWithCoaching(BaseModel):
    typical_week_training_review: str
    """Coach's review of the client's typical week of training"""

    weekly_mileage_target: str
    """Coach's prescribed weekly mileage target for the client"""

    planning: str
    """Internal planning for the client's training week"""

    training_week: List[TrainingSession]
    """Client's recommended training week"""

    @property
    def total_weekly_mileage(self) -> float:
        return sum(session.distance for session in self.training_week)

    def __str__(self):
        return f"TrainingWeekWithCoaching(typical_week_training_review={self.typical_week_training_review}, weekly_mileage_target={self.weekly_mileage_target}, planning={self.planning}, training_week={self.training_week})"

    def __repr__(self):
        return self.__str__()
