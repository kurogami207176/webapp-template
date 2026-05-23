# webapp-template

A template for shipping a Python Flask API to AWS. Clone it, rename things, and you have a working service with infrastructure, CI/CD, and deployment scripts already wired up.

## What's included

- **Flask API** — Python 3.12 + Gunicorn, with health check, hello, and 404 handlers out of the box
- **Docker** — multi-stage build, non-root user, production-ready image
- **AWS infrastructure as code** — four CloudFormation stacks: ECR repository, VPC/networking, ECS Fargate cluster + ALB, and an optional GitHub OIDC role
- **Deployment scripts** — `bin/` scripts to bootstrap infrastructure, build and push images, deploy, and smoke-test from your local machine
- **GitHub Actions pipeline** — runs tests, builds and pushes the Docker image to ECR, deploys the CloudFormation stack, forces a new ECS deployment, and runs a smoke test against the live URL
- **Smoke tests** — `bin/smoke-test.sh` hits every endpoint and asserts the response body; runs in CI after every deploy and locally on demand

## Stack

| Layer | Technology |
|---|---|
| API | Python 3.12 + Flask |
| Serving | Gunicorn (1 worker) |
| Registry | Amazon ECR |
| Compute | Amazon ECS Fargate |
| Load balancer | Application Load Balancer |
| Networking | VPC with public + private subnets, NAT gateway |
| IaC | AWS CloudFormation |
| CI/CD | GitHub Actions |
| Tests | pytest + smoke-test.sh |

## Local development

### Prerequisites

- Python 3.12+
- Everything else is handled by the scripts

### Run the app

```bash
./bin/run-local.sh
```

Creates `app/.venv`, installs dependencies, and starts Flask on port 3000 with auto-reload.

| Endpoint | Description |
|---|---|
| `GET /` | API info |
| `GET /hello` | Hello world |
| `GET /health` | Health check (used by ECS ALB target group) |

```bash
./bin/run-local.sh --port 8080  # use a different port
```

### Run unit tests

```bash
cd app
python3 -m venv .venv && source .venv/bin/activate  # first time only
pip install -r requirements-dev.txt                 # first time only
pytest tests/ -v
```

### Run smoke tests against a live URL

```bash
./bin/smoke-test.sh                             # resolves URL from production CF stack
./bin/smoke-test.sh --env staging               # staging stack
./bin/smoke-test.sh --url http://localhost:3000 # local dev server
```

## Project structure

```
├── app/                    # Flask application
│   ├── app.py              # Routes
│   ├── wsgi.py             # Gunicorn entry point
│   ├── requirements.txt    # Production dependencies
│   ├── requirements-dev.txt
│   ├── Dockerfile
│   └── tests/
├── bin/                    # Scripts
│   ├── run-local.sh        # Run app locally
│   ├── smoke-test.sh       # Smoke-test a live deployment
│   ├── deploy-infra.sh     # Bootstrap all CF stacks (one-time)
│   ├── push-image.sh       # Build & push Docker image to ECR
│   ├── deploy-app.sh       # Force new ECS deployment
│   └── setup-github-oidc.sh
├── cf/                     # CloudFormation templates
│   ├── ecr.yml             # ECR repository
│   ├── network.yml         # VPC, subnets, security groups
│   ├── ecs.yml             # ECS Fargate cluster, ALB, service
│   ├── iam-github-oidc.yml # GitHub Actions deploy role (optional)
│   ├── tags.json           # Tags applied to all stacks
│   └── parameters/
└── .github/workflows/
    └── deploy.yml          # CI + deploy pipeline
```

## Deployment

### First-time setup

```bash
# Deploy ECR, networking, and ECS stacks
./bin/deploy-infra.sh --env production

# Build and push the first image
./bin/push-image.sh --tag latest

# Verify it's live
./bin/smoke-test.sh
```

`APP_NAME` is derived automatically from the git remote. Pass `--app-name <name>` to override.

### Subsequent deploys

```bash
./bin/push-image.sh --tag v1.2.3
./bin/deploy-app.sh --tag v1.2.3
./bin/smoke-test.sh
```

### GitHub Actions CI/CD

Every push to `main` runs tests, deploys to production, and smoke-tests the result.  
Every push to `staging` does the same against the staging environment.

Required GitHub environment variables:

| Name | Where |
|---|---|
| `AWS_ACCESS_KEY_ID` | Variable |
| `AWS_ACCOUNT_ID` | Variable |
| `AWS_REGION` | Variable |
| `AWS_SECRET_ACCESS_KEY` | Secret |

See [cf/README.md](cf/README.md) for full infrastructure details.
