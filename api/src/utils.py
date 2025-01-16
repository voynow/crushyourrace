import datetime
from zoneinfo import ZoneInfo

from pydantic import BaseModel


def datetime_now_est() -> datetime.datetime:
    """
    Returns the current time in the specified timezone

    :param zone: The timezone name (default is 'America/New_York')
    :return: The current datetime in the specified timezone
    """
    return datetime.datetime.now(ZoneInfo("America/New_York"))


def make_tz_aware(dt: datetime.datetime) -> datetime.datetime:
    """Make a datetime object timezone-aware"""
    if dt.tzinfo is None:
        return dt.replace(tzinfo=ZoneInfo("America/New_York"))
    return dt


def round_all_floats(model: BaseModel, precision: int = 2) -> BaseModel:
    """Round all float fields in a pydantic model to a given precision"""
    for field_name, field in model.__fields__.items():
        if (
            isinstance(field.type_, type)
            and issubclass(field.type_, float)
            and getattr(model, field_name) is not None
        ):
            setattr(model, field_name, round(getattr(model, field_name), precision))
    return model


def get_last_sunday() -> datetime.datetime:
    today = datetime_now_est().today()
    days_since_sunday = (today.weekday() + 1) % 7
    return today - datetime.timedelta(days=days_since_sunday)
