import logging
import os

import pytest
from fastapi.testclient import TestClient
from freezegun import freeze_time
from src import auth_manager, supabase_client
from src.apn import send_push_notification
from src.main import app
from src.types.training_week import FullTrainingWeek
from src.types.update_pipeline import ExeType
from src.update_pipeline import _update_training_week
from src.utils import get_last_sunday

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = TestClient(app)


@pytest.fixture(autouse=True, scope="session")
def setup_test_environment():
    os.environ["TEST_FLAG"] = "true"
    auth_manager.authenticate_athlete(os.environ["JAMIES_ATHLETE_ID"])


def test_get_training_week():
    """Test successful retrieval of training week"""
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])

    response = client.get(
        "/training_week/", headers={"Authorization": f"Bearer {user_auth.jwt_token}"}
    )
    assert FullTrainingWeek(**response.json())
    assert response.status_code == 200


def test_update_device_token():
    """Test successful update of device token"""
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])
    response = client.post(
        "/device_token/",
        json={"device_token": user_auth.device_token},
        headers={"Authorization": f"Bearer {user_auth.jwt_token}"},
    )
    assert response.status_code == 200


def test_update_preferences():
    """Test successful update of preferences"""
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    response = client.post(
        "/preferences/",
        json=user.preferences.dict(),
        headers={"Authorization": f"Bearer {user_auth.jwt_token}"},
    )
    assert response.status_code == 200


def test_get_profile():
    """Test successful retrieval of profile"""
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])
    response = client.get(
        "/profile/", headers={"Authorization": f"Bearer {user_auth.jwt_token}"}
    )
    assert response.status_code == 200


def test_get_weekly_summaries():
    """Test successful retrieval of weekly summaries"""
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])
    response = client.get(
        "/weekly_summaries/", headers={"Authorization": f"Bearer {user_auth.jwt_token}"}
    )
    assert response.status_code == 200


def test_authenticate():
    """Test successful authentication, only covering does_user_exist"""
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    assert supabase_client.does_user_exist(user.athlete_id)


def test_strava_webhook():
    """Test successful Strava webhook"""
    event = {
        "subscription_id": 288883,
        "aspect_type": "update",
        "object_type": "activity",
        "object_id": 18888888889,
        "owner_id": 98888886,
        "event_time": 1731515699,
        "updates": {"title": "Best running weather ❄️"},
    }
    response = client.post("/strava-webhook/", json=event)
    assert response.status_code == 200


def test_update_training_week_generate_training_recommendation():
    """
    Test successful update of new week

    When the race date & distance are not set, we go through the default
    recommendation generation pipeline using weekly summaries
    """
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    user.preferences.race_date = None
    user.preferences.race_distance = None

    @freeze_time(f"{get_last_sunday()} 12:00:00")
    def frozen_update_training_week_new_week():
        return _update_training_week(user, ExeType.NEW_WEEK)

    response = frozen_update_training_week_new_week()
    assert isinstance(response, FullTrainingWeek)


def test_update_training_week_generate_training_plan():
    """
    Test successful update of new week

    When race date & distance are set, we go through the full training plan
    generation pipeline
    """
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    assert user.preferences.race_date is not None
    assert user.preferences.race_distance is not None

    @freeze_time(f"{get_last_sunday()} 12:00:00")
    def frozen_update_training_week_new_week():
        return _update_training_week(user, ExeType.MID_WEEK)

    response = frozen_update_training_week_new_week()
    assert isinstance(response, FullTrainingWeek)


def test_update_training_week_mid_week():
    """Test successful update of mid week"""
    user = supabase_client.get_user(os.environ["JAMIES_ATHLETE_ID"])
    response = _update_training_week(user, ExeType.MID_WEEK)
    assert isinstance(response, FullTrainingWeek)


def test_apple_push_notification():
    user_auth = supabase_client.get_user_auth(os.environ["JAMIES_ATHLETE_ID"])
    send_push_notification(
        device_token=user_auth.device_token,
        title="Test Notification ✔️",
        body="Don't panic! This is only a test.",
    )
    user_auth = supabase_client.get_user_auth(os.environ["RACHELS_ATHLETE_ID"])
    send_push_notification(
        device_token=user_auth.device_token,
        title="Test Notification ✔️",
        body="Don't panic! This is only a test.",
    )
