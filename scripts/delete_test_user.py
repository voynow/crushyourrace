import os

from dotenv import load_dotenv
from supabase import Client, create_client

load_dotenv()


def init() -> Client:
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_KEY"]
    return create_client(url, key)


client = init()


def delete_test_user() -> None:
    """
    Delete test user from user and user_auth tables
    """
    clear_tables = [
        "user_combined",
        "training_week",
        "training_plan",
        "mileage_recommendation",
    ]

    for table in clear_tables:
        client.table(table).delete().eq(
            column="athlete_id", value=os.environ["TEST_USER_ATHLETE_ID"]
        ).execute()


if __name__ == "__main__":
    delete_test_user()
