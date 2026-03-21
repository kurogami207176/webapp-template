# webapp-template

A production-ready template for building web applications and APIs.

## Stack

| Layer | Technology |
|---|---|
| API | Python + FastAPI |
| Frontend | React + TypeScript (Next.js 14) |
| Database | PostgreSQL + SQLAlchemy (async) + Alembic |
| IaC | AWS CloudFormation (App Runner + ECR) |
| CI/CD | GitHub Actions |
| Containers | Docker + Docker Compose |
| API Tests | pytest + httpx |
| E2E Tests | Playwright |

## Getting started

### Prerequisites

- Python 3.12+
- Node.js 20+
- Docker & Docker Compose

### Local development

```bash
# First-time setup
./scripts/setup-local.sh

# Start all services
docker compose -f docker/docker-compose.yml up
```

API: http://localhost:8000
API docs: http://localhost:8000/docs
Web: http://localhost:3000

### Running tests

```bash
# API tests (unit + integration) — uses SQLite, no running DB needed
cd api
source .venv/bin/activate
pytest

# With coverage
pytest --cov=src --cov-report=term-missing

# E2E tests — requires the app running locally first
cd web
npx playwright install chromium  # first time only
npx playwright test
```

## Project structure

```
├── api/        # FastAPI application
├── web/        # Next.js frontend
├── infra/      # CloudFormation templates
├── scripts/    # Operational scripts
└── docker/     # Docker Compose for local dev
```

## Deployment

See [infra/README.md](infra/README.md) for CloudFormation deployment instructions.
