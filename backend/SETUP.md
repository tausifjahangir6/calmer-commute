# Calmer Commute Backend Setup

## Technology

- Python
- Flask
- Application factory structure
- Default local port: 5000

## Create the virtual environment

From the repository root:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
```

## Install dependencies

```bash
pip install -r requirements.txt
```

## Run locally

```bash
python run.py
```

Open:

- API root: `http://localhost:5000`
- Health check: `http://localhost:5000/api/health`

## Stop the backend

Press:

```text
Control + C
```

Then deactivate the environment:

```bash
deactivate
```

## Branch workflow

Backend development occurs on the `backend` branch.

```text
backend → pull request → development → pull request → main
```

Do not push backend implementation directly to `development` or `main`.