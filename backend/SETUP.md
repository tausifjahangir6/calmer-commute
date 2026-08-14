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
pip install -r requirements.txt -r requirements-dev.txt -r ../ai/requirements.txt
```

The `ai/requirements.txt` install (joblib, scikit-learn) is required for
`/api/crowd` and `/api/predictions` to load the forecast model. Without it,
`app/ai/forecast.py`'s model import fails silently underneath a broad
`except Exception` in `routes.py`, and `/api/crowd` returns a misleading
"The City feed could not be reached" instead of the real cause. The
Dockerfile already installs this; local `pip install -r requirements.txt`
alone does not.

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