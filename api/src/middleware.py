import json
import logging
import time
import traceback
import uuid
from datetime import datetime, timezone
from typing import Callable

from fastapi import Request, Response
from src.auth_manager import decode_jwt
from src.email_manager import send_alert_email

logger = logging.getLogger("uvicorn.error")


def get_user_info(request: Request) -> str:
    """
    Extract user info from request headers

    :param request: incoming FastAPI Request object
    :return: user's athlete_id or "unauthenticated"
    """
    try:
        if "authorization" in request.headers:
            token = request.headers["authorization"].split(" ")[1]
            return f"athlete_id={decode_jwt(token, verify_exp=False)}"
    except Exception:
        pass
    return "unauthenticated"


async def get_response_body(response: Response) -> bytes:
    """
    Collect response body chunks

    :param response: FastAPI Response object
    :return: response body as bytes
    """
    body = b""
    async for chunk in response.body_iterator:
        body += chunk
    return body


async def log_request(request_id: str, request: Request, user_info: str) -> float:
    """
    Log incoming request details with request body while preserving it for endpoint use
    and return the request start time for profiling.

    :param request_id: unique request identifier
    :param request: FastAPI Request object
    :param user_info: user's athlete_id or "unauthenticated"
    :return: start time of request processing
    """
    # Create a copy of the body
    body = await request.body()

    # Store the body for later use by endpoints
    async def receive():
        return {"type": "http.request", "body": body}

    request._receive = receive

    try:
        body_str = body.decode() if body else None
    except UnicodeDecodeError:
        body_str = "<binary>"

    log_data = {
        "request_id": request_id,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user": user_info,
        "method": request.method,
        "path": request.url.path,
        "query": dict(request.query_params),
        "client_ip": request.client.host,
        "body": body_str,
    }
    logger.info(f"REQUEST: {log_data}")

    # Return the start time for profiling
    return time.monotonic()


def log_response(
    request_id: str, response: Response, body: bytes, duration: float
) -> None:
    """
    Log response details with profiling duration.

    :param request_id: unique request identifier
    :param response: FastAPI Response object
    :param body: response body as bytes
    :param duration: time taken to process the request in seconds
    """
    log_data = {
        "request_id": request_id,
        "status_code": response.status_code,
        "body": body.decode(),
        "duration": f"{round(duration, 2)}s",
    }
    logger.info(f"RESPONSE: {log_data}")


def create_error_log(
    error: Exception,
    traceback: str,
    endpoint: str,
    user_info: str,
    request: Request,
) -> dict:
    """
    Create error log dictionary

    :param e: Exception object
    :param endpoint: endpoint name
    :param user_info: user's athlete_id or "unauthenticated"
    :param request: FastAPI Request object
    :return: error log dictionary
    """
    return {
        "error": str(error),
        "traceback": traceback,
        "type": type(error).__name__,
        "endpoint": endpoint,
        "user": user_info,
        "client_ip": request.client.host,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


async def log_and_handle_errors(request: Request, call_next: Callable) -> Response:
    """
    Middleware to log requests/responses, handle errors, and add profiling.

    :param request: incoming FastAPI Request object
    :param call_next: next middleware function
    :return: Response or error dict
    """
    request_id = str(uuid.uuid4())
    user_info = get_user_info(request)
    endpoint = f"{request.method} {request.url.path}"

    try:
        start_time = await log_request(request_id, request, user_info)

        response = await call_next(request)
        response_body = await get_response_body(response)

        duration = time.monotonic() - start_time
        log_response(request_id, response, response_body, duration)

        return Response(
            content=response_body,
            status_code=response.status_code,
            headers=dict(response.headers),
            media_type=response.media_type,
        )

    except Exception as e:
        error = create_error_log(
            error=e,
            traceback=traceback.format_exc(),
            endpoint=endpoint,
            user_info=user_info,
            request=request,
        )
        logger.error(f"ERROR: {error}")
        send_alert_email(
            subject=f"API Error: {endpoint} [{user_info}] - {type(e).__name__}",
            text_content=json.dumps(error, indent=4),
        )
        return Response(
            content=json.dumps({"detail": f"Internal server error: {error}"}),
            status_code=500,
            media_type="application/json",
        )
