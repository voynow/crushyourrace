import os

from fastapi.testclient import TestClient
from src.main import app
from src.supabase_client import get_user_auth
from src.types.training_week import TrainingWeek

client = TestClient(app)


def test_get_training_week_success():
    """Test successful retrieval of training week"""
    user_auth = get_user_auth(os.environ["JAMIES_ATHLETE_ID"])

    response = client.get(
        "/training_week/", headers={"Authorization": f"Bearer {user_auth.jwt_token}"}
    )
    assert TrainingWeek(**response.json())
    assert response.status_code == 200