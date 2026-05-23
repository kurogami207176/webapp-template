# webapp-template

A production-ready Flask API template with ECR + ECS Fargate deployment on AWS.

## Stack

| Layer | Technology |
|---|---|
| API | Python 3.12 + Flask |
| Serving | Gunicorn |
| IaC | AWS CloudFormation (ECR + ECS Fargate + ALB) |
| CI/CD | GitHub Actions |
| Containers | Docker |
| Tests | pytest |

## Local development

### Prerequisites

- Python 3.12+
- `./bin/run-local.sh` handles everything else (virtualenv, dependencies)

### Run the app

```bash
./bin/run-local.sh
```

The script will:
1. Create `app/.venv` if it doesn't exist
2. Install dependencies from `app/requirements-dev.txt`
3. Start Flask in development mode with auto-reload on port 3000

Available endpoints:

| Endpoint | Description |
|---|---|
| `GET /` | API info |
| `GET /hello` | Hello world |
| `GET /health` | Health check (used by ECS target group) |

To use a different port:

```bash
./bin/run-local.sh --port 8080
```

### Run tests

```bash
cd app
python3 -m venv .venv && source .venv/bin/activate  # first time only
pip install -r requirements-dev.txt                 # first time only
pytest tests/ -v
```

## Project structure

```
├── app/                  # Flask application
│   ├── app.py            # Routes
│   ├── wsgi.py           # Gunicorn entry point
│   ├── requirements.txt  # Production dependencies
│   ├── requirements-dev.txt
│   ├── Dockerfile
│   └── tests/
├── bin/                  # Scripts
│   ├── run-local.sh      # Run app locally
│   ├── deploy-infra.sh   # Bootstrap all CF stacks (one-time)
│   ├── push-image.sh     # Build & push Docker image to ECR
│   ├── deploy-app.sh     # Force new ECS deployment
│   └── setup-github-oidc.sh
├── cf/                   # CloudFormation templates
│   ├── ecr.yml           # ECR repository
│   ├── network.yml       # VPC, subnets, security groups
│   ├── ecs.yml           # ECS cluster, ALB, service
│   ├── iam-github-oidc.yml
│   └── parameters/
└── .github/workflows/
    └── deploy.yml        # CI + deploy pipeline
```

## Deployment

### First-time AWS setup

```bash
# 1. Deploy all infrastructure stacks
./bin/deploy-infra.sh --env production --region ap-southeast-2

# 2. Push an initial image
./bin/push-image.sh --tag latest
```

### GitHub Actions CI/CD

Push to `main` → deploys to production automatically.  
Push to `staging` → deploys to staging.

Required GitHub environment variables:

| Name | Where |
|---|---|
| `AWS_ACCESS_KEY_ID` | Variable |
| `AWS_ACCOUNT_ID` | Variable |
| `AWS_REGION` | Variable |
| `AWS_SECRET_ACCESS_KEY` | Secret |

See [cf/README.md](cf/README.md) for full infrastructure details.
