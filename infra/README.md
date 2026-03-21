# Infrastructure (CloudFormation)

Deploys the API to AWS App Runner backed by an ECR container registry.

## Prerequisites

- AWS CLI configured
- Docker (for building and pushing images)

## Architecture

- **ECR**: Container registry for API images
- **App Runner**: Managed container service — no VPC, load balancer, or cluster to manage

## Deploy steps

### 1. Bootstrap ECR (one-time)

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/ecr.yml \
  --stack-name webapp-ecr \
  --region us-east-1
```

### 2. Build and push image

```bash
./scripts/deploy.sh --env staging --tag $(git rev-parse --short HEAD)
```

### 3. Deploy App Runner

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/app-runner.yml \
  --stack-name webapp-api-staging \
  --parameter-overrides file://infra/cloudformation/parameters/staging.json \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## Updating the deployment

Re-run `deploy.sh` to push a new image, then update the CloudFormation stack with the new image tag.
