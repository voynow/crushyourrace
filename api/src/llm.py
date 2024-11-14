import json
import time
from typing import Dict, List, Optional, Type

from dotenv import load_dotenv
from openai import OpenAI
from openai.types.chat.chat_completion_message import ChatCompletionMessage
from pydantic import BaseModel, ValidationError

load_dotenv()
client = OpenAI()


def get_completion(
    messages: List[ChatCompletionMessage],
    model: str = "gpt-4o-2024-08-06",
    response_format: Optional[Dict] = None,
):
    response = client.chat.completions.create(
        model=model, messages=messages, response_format=response_format
    )
    return response.choices[0].message.content


def get_completion_json(
    message: str,
    response_model: Type[BaseModel],
    model: str = "gpt-4o-2024-08-06",
    max_retries: int = 3,
    retry_delay: float = 1.0,
) -> BaseModel:
    """
    Get a JSON completion from the LLM and parse it into a Pydantic model.

    :param message: The message to send to the LLM.
    :param response_model: The Pydantic model to parse the response into.
    :param model: The model to use for the completion.
    :param max_retries: The maximum number of retries to attempt.
    :param retry_delay: The delay between retries in seconds.
    :return: parsed Pydantic model
    """
    response_model_content = (
        f"Your json response must follow the following: {response_model.schema()=}"
    )

    messages = [
        {
            "role": "system",
            "content": f"You are a helpful assistant designed to output JSON. {response_model_content}",
        },
        {"role": "user", "content": message},
    ]

    for attempt in range(max_retries):
        try:
            response_str = get_completion(
                model=model,
                messages=messages,
                response_format={"type": "json_object"},
            )
            response = json.loads(response_str)
            return response_model(**response)
        except (json.JSONDecodeError, ValidationError) as e:
            if attempt == max_retries - 1:
                raise Exception(
                    f"Failed to parse JSON after {max_retries} attempts: {e}"
                )
            time.sleep(retry_delay)
        except Exception as e:
            raise Exception(f"Failed to get a valid response: {response_str=}, {e=}")

    raise Exception(f"Failed to get a valid response after {max_retries} attempts")
