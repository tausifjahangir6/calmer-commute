# Calmer Commute Docker Setup

## Prerequisites

Install and open Docker Desktop.

Confirm Docker is available:

```bash
docker --version
docker compose version
```

## First-time setup

From the repository root, run:

```bash
docker compose up --build
```

This will:

- pull the required Node and Python base images
- build the Next.js frontend image
- build the Flask backend image
- create the containers
- create the Docker network
- create the frontend dependency volume
- start both services

Open:

- Frontend: `http://localhost:3000`
- Backend: `http://localhost:5000`
- Backend health check: `http://localhost:5000/api/health`

## Daily use: Docker Desktop

After the first successful build, the containers can be managed through Docker Desktop.

In Docker Desktop, locate the `calmer-commute` application and use:

- Start
- Stop
- Restart
- View logs
- Open container terminal

This is suitable for normal daily development.

## Daily use: terminal commands

Start existing containers:

```bash
docker compose start
```

Stop containers while keeping them available in Docker Desktop:

```bash
docker compose stop
```

Start the application and attach to its logs:

```bash
docker compose up
```

Run in the background:

```bash
docker compose up -d
```

View logs:

```bash
docker compose logs -f
```

## When to rebuild

Rebuild after changing:

- a Dockerfile
- `compose.yaml`
- `package.json`
- `package-lock.json`
- `requirements.txt`
- installed dependencies

Run:

```bash
docker compose up --build
```

## Clean reset

Use this only when troubleshooting or intentionally recreating the containers:

```bash
docker compose down
```

This removes the containers and Compose network but keeps the source code and Docker images.

To also remove named volumes:

```bash
docker compose down -v
```

Do not use `-v` for normal daily stopping because dependencies may need to be installed again.

## Services and ports

- Next.js frontend: `localhost:3000`
- Flask backend: `localhost:5000`
- Backend health endpoint: `localhost:5000/api/health`

Inside Docker:

- frontend runs on container port `3000`
- backend runs on container port `5000`

## Common issue: port already in use

Check which process is using the required port:

```bash
lsof -nP -iTCP:3000 -sTCP:LISTEN
lsof -nP -iTCP:5000 -sTCP:LISTEN
```

Stop the conflicting application, then run:

```bash
docker compose up
```

On macOS, AirPlay Receiver may use port `5000`. AirDrop is separate and continues to work if AirPlay Receiver is disabled.

## Common issue: Docker daemon not running

Open Docker Desktop and wait until Docker is running.

Then check:

```bash
docker info
```

After Docker responds successfully, run:

```bash
docker compose up
```

## Branch workflow

Shared Docker configuration is integrated through:

```text
docker-setup → pull request → development
```

After the pull request is merged, the temporary `docker-setup` branch can be deleted.

Specialist development continues on:

- `frontend`
- `backend`
- `data`
- `AI`