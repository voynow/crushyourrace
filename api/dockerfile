FROM --platform=linux/amd64 python:3.11-slim

WORKDIR /app

COPY . /app

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 80

CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "80", "--log-level", "info"]