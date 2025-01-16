import os


def get_user_table_name() -> str:
    """
    Inject test_user table name during testing

    :return: The name of the user table
    """
    return "user_combined"


def get_training_week_table_name() -> str:
    """
    Inject test_training_week table name during testing

    :return: The name of the training_week table
    """
    if os.environ.get("TEST_FLAG", "false") == "true":
        return "test_training_week"
    return "training_week"


def get_mileage_recommendation_table_name() -> str:
    """
    Inject test_mileage_recommendation table name during testing

    :return: The name of the mileage_recommendation table
    """
    if os.environ.get("TEST_FLAG", "false") == "true":
        return "test_mileage_recommendation"
    return "mileage_recommendation"


def get_training_plan_table_name() -> str:
    """
    Inject test_training_plan table name during testing

    :return: The name of the training_plan table
    """
    if os.environ.get("TEST_FLAG", "false") == "true":
        return "test_training_plan"
    return "training_plan"


def get_feedback_table_name() -> str:
    """
    Inject test_feedback table name during testing

    :return: The name of the feedback table
    """
    if os.environ.get("TEST_FLAG", "false") == "true":
        return "test_feedback"
    return "feedback"
