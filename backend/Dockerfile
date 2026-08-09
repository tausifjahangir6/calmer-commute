FROM python:3.12-slim-bookworm

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copy dependency files first so Docker can cache installs efficiently
COPY backend/requirements.txt backend/requirements.txt
COPY backend/requirements-dev.txt backend/requirements-dev.txt
COPY ai/requirements.txt ai/requirements.txt

# Install backend + AI dependencies
RUN pip install --no-cache-dir \
    -r backend/requirements-dev.txt \
    -r ai/requirements.txt

# Copy application code
COPY backend/ backend/
COPY ai/ ai/

# Run Flask from backend directory
WORKDIR /app/backend

EXPOSE 5000

CMD ["python", "run.py"]