from pydantic import BaseModel


class Speed(BaseModel):
    min: int
    sec: int


class Split(BaseModel):
    distance_in_miles: float
    average_speed_per_mile: Speed
    elevation_gain_in_feet: float
    average_heartrate: float


class DetailedActivity(BaseModel):
    distance_in_miles: float = 0.0
    average_speed_per_mile: Speed = Speed(min=0, sec=0)
    elevation_gain_in_feet: float = 0.0
    average_heartrate: float = 0.0
    splits: list[Split] = []
