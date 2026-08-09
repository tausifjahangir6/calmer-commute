# Development and Docker Instructions

## 1. Branch Workflow

Each team member must work on their assigned branch.

| Workstream | Branch |
|---|---|
| Frontend | `frontend` |
| Backend | `backend` |
| Data | `data` |
| AI | `AI` |

Do not develop directly on `development` or `main`.

Normal integration flow:

```text
frontend / backend / data / AI
            ↓
      Pull Request
            ↓
      development
            ↓
      Pull Request
            ↓
          main
```

`development` is the shared integration branch.

`main` is the release and final-submission branch.

---

## 2. First-Time Setup

Install:

- Git
- VS Code
- Docker Desktop

Open Docker Desktop and wait until Docker is running.

Open VS Code go to preferred folder/location

Open a terminal inside vs code

Clone the repository:

```bash
git clone https://github.com/tausifjahangir6/calmer-commute.git
cd calmer-commute
```

Switch to your assigned branch:

```bash
git switch <your-branch> 
```

Example:

```bash
git switch frontend
```

Build and start the complete environment:

```bash
docker compose up --build
```

Docker will:

- pull the required Node.js and Python images
- install frontend dependencies
- install backend dependencies
- create the containers
- create the Docker network
- start the frontend and backend services

Open:

- Frontend: `http://localhost:3000`
- Backend: `http://localhost:5000`
- Backend health check: `http://localhost:5000/api/health`

---
If all the links work make sure you close the tabs/links after viewing/working.

## 3. Daily Docker Use

After the first successful build, developers may use either Docker Desktop or terminal commands.

### Option A: Docker Desktop

Open Docker Desktop and locate the `calmer-commute` application.

Use Docker Desktop to:

- start containers
- stop containers
- restart containers
- view logs
- open a terminal inside a container

### Option B: Terminal

Start existing containers:

```bash
docker compose start
```

Stop containers while keeping them available in Docker Desktop:

```bash
docker compose stop
```

Start and attach to logs:

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

---

## 4. Live Development

When the containers are running, edit and save source files normally.

Frontend developers primarily work in:

```text
frontend/src/
```

Backend developers primarily work in:

```text
backend/app/
```

Next.js and Flask are configured for development, so source-code changes should normally appear without rebuilding the Docker images.

Refresh the browser after saving if the change does not appear automatically.

---

## 5. When Docker Must Be Rebuilt

Run:

```bash
docker compose up --build
```

after changing any dependency or Docker configuration file.

Examples include:

### Frontend dependencies

```text
frontend/package.json
frontend/package-lock.json
```

### Backend dependencies

```text
backend/requirements.txt
ai/requirements.txt
```

### Docker configuration

```text
compose.yaml
frontend/Dockerfile
frontend/.dockerignore
backend/Dockerfile
backend/.dockerignore
```

Normal changes to React, Next.js, Flask, CSS, tests or application logic do not usually require a rebuild.

---

## 6. Frontend File Rules

Frontend developers may modify:

```text
frontend/src/
frontend/public/
frontend/package.json
frontend/package-lock.json
frontend/next.config.ts
frontend/tsconfig.json
frontend/eslint.config.*
```

Add or remove dependencies using npm commands.

Example:

```bash
cd frontend
npm install axios
cd ..
docker compose up --build
```

Do not manually edit `package-lock.json`.

It should be updated automatically by npm.

---

## 7. Backend File Rules

Backend developers may modify:

```text
backend/app/
backend/tests/
backend/run.py
backend/requirements.txt
```

Add only genuine Python dependencies to `requirements.txt`.

After changing Python dependencies, rebuild:

```bash
docker compose up --build
```

---

## 8. Data and AI File Rules

Data developers primarily work in:

```text
data/
database/
scripts/
```

AI developers primarily work in:

```text
ai/
```

Changes outside the assigned workstream should be discussed with the team first.

---

## 9. Shared Project Files

These files affect the whole team and must not be changed casually:

```text
compose.yaml
frontend/Dockerfile
frontend/.dockerignore
backend/Dockerfile
backend/.dockerignore
.gitignore
DOCKER_SETUP.md
CONTRIBUTING.md
```

Shared configuration changes should follow this workflow:

```text
temporary branch
      ↓
local testing
      ↓
Pull Request
      ↓
development
```

Examples of temporary branch names:

```text
docker-update
docs-update
config-update
ci-setup
```

Delete the temporary branch after the Pull Request is merged.

---

## 10. Files That Must Never Be Committed

Never commit generated or local environment files such as:

```text
node_modules/
.next/
.venv/
venv/
__pycache__/
.pytest_cache/
.env
.DS_Store
```

Never commit:

- passwords
- API keys
- authentication tokens
- private credentials
- secrets
- personal data

Use `.env.example` to document required environment variable names without real values.

---

## 11. Starting Work Each Day

Before beginning work:

```bash
git switch <your-branch>
git pull origin <your-branch>
```

Then start the containers using Docker Desktop or:

```bash
docker compose start
```

Confirm the application is available before making changes.

---

## 12. Saving Work

Check changes:

```bash
git status
```

Stage relevant files:

```bash
git add <files>
```

Commit with a clear message:

```bash
git commit -m "feat: describe the change"
```

Push to the assigned branch:

```bash
git push origin <your-branch>
```

Do not push directly to `development` or `main`.

---

## 13. Pull Requests

When work is complete, open a Pull Request into:

```text
development
```

Examples:

```text
frontend → development
backend → development
data → development
AI → development
```

The Pull Request should include:

### Summary

What changed?

### Purpose

Why was the change required?

### Related Work

- Epic:
- User Story:
- LeanKit card:

### Testing

What was tested?

### Evidence

- screenshots
- API responses
- test results
- demonstrations
- repository links

### Known Limitations

Any unresolved issues or deferred work.

After the integrated iteration is tested and submission-ready:

```text
development → main
```

---

## 14. Port Conflict Troubleshooting

If Docker reports that a port is already in use, check:

```bash
lsof -nP -iTCP:3000 -sTCP:LISTEN
lsof -nP -iTCP:5000 -sTCP:LISTEN
```

Stop the conflicting application, then restart:

```bash
docker compose up
```

On macOS, AirPlay Receiver may use port `5000`.

AirDrop is a separate feature.

---

## 15. Docker Troubleshooting

If Docker cannot connect to the daemon:

1. Open Docker Desktop.
2. Wait until Docker is running.
3. Check:

```bash
docker info
```

Then start the project:

```bash
docker compose up
```

For a clean reset:

```bash
docker compose down
docker compose up --build
```

Use:

```bash
docker compose down -v
```

only when intentionally removing named volumes and recreating dependencies.