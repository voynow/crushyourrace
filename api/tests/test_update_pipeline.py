import logging
import os
from datetime import timedelta

import pytest
from scripts.delete_test_user import delete_test_user_training_plans
from src import auth_manager, supabase_client
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.update_pipeline import _update_training_week, refresh_user_data
from src.utils import datetime_now_est, get_last_sunday

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logging.getLogger("httpx").setLevel(logging.WARNING)
logging.getLogger("stravalib").setLevel(logging.WARNING)


@pytest.fixture(autouse=True, scope="session")
def setup_test_environment():
    os.environ["TEST_FLAG"] = "true"
    auth_manager.authenticate_athlete(os.environ["JAMIES_ATHLETE_ID"])


@pytest.mark.asyncio
async def test_refresh_user_data_on_sunday():
    """
    Test successful refresh of user data
    """
    delete_test_user_training_plans()
    user = supabase_client.get_user(os.environ["TEST_USER_ATHLETE_ID"])
    response = await refresh_user_data(user, dt=get_last_sunday())
    assert isinstance(response, dict)


@pytest.mark.asyncio
async def test_update_training_week_gen_training_plan():
    """
    gen_training_plan_pipeline is called when the race date & distance are set
    """
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    response = await _update_training_week(user, ExeType.NEW_WEEK, dt=get_last_sunday())
    assert isinstance(response, FullTrainingWeek)


@pytest.mark.asyncio
async def test_update_training_week_mid_week():
    """
    Test successful update of mid week

    This is the only mid week update path
    """
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    response = await _update_training_week(
        user, ExeType.MID_WEEK, dt=datetime_now_est()
    )
    assert isinstance(response, FullTrainingWeek)


@pytest.mark.asyncio
async def test_refresh_user_data_on_monday():
    """
    Test successful refresh of user data
    """
    delete_test_user_training_plans()
    user = supabase_client.get_user(os.environ["TEST_USER_ATHLETE_ID"])
    response = await refresh_user_data(user, dt=get_last_sunday() + timedelta(days=1))
    assert isinstance(response, dict)
