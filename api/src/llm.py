import json
import time
from typing import Dict, List, Optional, Type

from dotenv import load_dotenv
from openai import OpenAI
from openai.types.chat.chat_completion import ChatCompletion
from openai.types.chat.chat_completion_message import ChatCompletionMessage
from pydantic import BaseModel, ValidationError
from src.constants import OBSERVE_FILE

load_dotenv()
client = OpenAI()


def observe(
    generation_name: str,
    messages: List[ChatCompletionMessage],
    response: ChatCompletion,
    duration: float,
):
    with open(OBSERVE_FILE, "a") as f:
        f.write(
            json.dumps(
                {
                    "generation_name": generation_name,
                    "messages": [message["content"] for message in messages],
                    "response_id": response.id,
                    "content": response.choices[0].message.content,
                    "model": response.model,
                    "completion_tokens": response.usage.completion_tokens,
                    "prompt_tokens": response.usage.prompt_tokens,
                    "total_tokens": response.usage.total_tokens,
                    "duration": duration,
                }
            )
            + "\n"
        )


def _get_completion(
    messages: List[ChatCompletionMessage],
    model: str = "gpt-4o",
    response_format: Optional[Dict] = None,
    generation_name: Optional[str] = None,
):
    start_time = time.time()
    response = client.chat.completions.create(
        model=model, messages=messages, response_format=response_format
    )
    duration = time.time() - start_time
    observe(
        generation_name=generation_name,
        messages=messages,
        response=response,
        duration=duration,
    )

    return response.choices[0].message.content


def get_completion(
    message: str,
    model: Optional[str] = "gpt-4o",
    generation_name: Optional[str] = None,
):
    """
    LLM completion with raw string response

    :param message: The message to send to the LLM.
    :param model: The model to use for the completion.
    :return: The raw string response from the LLM.
    """
    messages = [{"role": "user", "content": message}]
    return _get_completion(
        messages=messages, model=model, generation_name=generation_name
    )


def get_completion_json(
    message: str,
    response_model: Type[BaseModel],
    model: str = "gpt-4o",
    max_retries: int = 3,
    retry_delay: float = 1.0,
    generation_name: Optional[str] = None,
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

    response_str = "Completion failed."
    for attempt in range(max_retries):
        try:
            response_str = _get_completion(
                model=model,
                messages=messages,
                response_format={"type": "json_object"},
                generation_name=generation_name,
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
