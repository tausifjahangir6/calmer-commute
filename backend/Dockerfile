FROM python:3.12-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Requirements copied and installed BEFORE source code, same caching
# pattern as the original single-service Dockerfile -- pip install only
# re-runs when a requirements file actually changes, not on every source
# edit. Two files instead of one: ai/requirements.txt is the single
# source of truth for AI dependencies, not duplicated into
# backend/requirements.txt.
COPY backend/requirements.txt backend/requirements.txt
COPY ai/requirements.txt ai/requirements.txt

RUN pip install --no-cache-dir -r backend/requirements.txt -r ai/requirements.txt

COPY backend/ backend/
COPY ai/ ai/

# WORKDIR moves to backend/ after copying, so `python run.py` and any
# relative paths inside the Flask app behave exactly as before the
# context change -- /app/backend is now what /app used to be.
WORKDIR /app/backend

EXPOSE 5000

CMD ["python", "run.py"]
