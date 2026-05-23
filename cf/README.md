# CloudFormation Templates

Infrastructure-as-Code for the webapp-template ECS deployment.

## Architecture

```
Internet
   │
  ALB (public subnets, port 80)
   │
  ECS Fargate Service (private subnets, port 3000)
   │
  ECR (Docker image registry)
```

## Stacks

| File | Stack name | Purpose |
|------|-----------|---------|
| `ecr.yml` | `webapp-template-ecr` | ECR repository |
| `network.yml` | `webapp-template-network-<env>` | VPC, subnets, security groups |
| `ecs.yml` | `webapp-template-ecs-<env>` | ECS cluster, task def, ALB, service |
| `iam-github-oidc.yml` | `webapp-template-github-oidc` | GitHub Actions deploy role (one-time) |

## First-time setup

### 1. Deploy infrastructure

```bash
# Deploys ECR → Network → ECS in one shot
./bin/deploy-infra.sh --env production --region us-east-1
```

### 2. Push your first image

```bash
./bin/push-image.sh --tag v1.0.0
```

### 3. Set up GitHub OIDC (for CI/CD)

```bash
./bin/setup-github-oidc.sh \
  --github-org  YOUR_ORG \
  --github-repo webapp-template \
  --region us-east-1
```

Copy the printed `AWS_DEPLOY_ROLE_ARN` into your GitHub repository secrets.

Add `AWS_REGION` as a repository variable (e.g. `us-east-1`).

## Subsequent deploys

```bash
# From local machine
./bin/deploy-app.sh --env production --tag v1.2.3

# Or push to main → GitHub Actions handles it automatically
```

## Parameters

See `parameters/production.json` and `parameters/staging.json`.

## Stack outputs

Each stack exports its key resources so dependent stacks can `Fn::ImportValue` them without hardcoding ARNs.
