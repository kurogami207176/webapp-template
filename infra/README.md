# Infrastructure (CloudFormation)

Deploys the API to AWS App Runner backed by ECR and DynamoDB.

## Prerequisites

- AWS CLI configured
- Docker (for building and pushing images)

## Architecture

- **ECR**: Container registry for API images
- **DynamoDB**: Serverless tables for users and sessions (no RDS/VPC needed)
- **App Runner**: Managed container service — no load balancer or cluster to manage

## Deploy steps

### 1. Bootstrap ECR (one-time)

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/ecr.yml \
  --stack-name webapp-ecr \
  --region us-east-1
```

### 2. Deploy DynamoDB tables (one-time per environment)

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/dynamodb.yml \
  --stack-name webapp-dynamodb-staging \
  --parameter-overrides Environment=staging PointInTimeRecovery=false \
  --region us-east-1
```

For production, enable point-in-time recovery:
```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/dynamodb.yml \
  --stack-name webapp-dynamodb-production \
  --parameter-overrides Environment=production PointInTimeRecovery=true \
  --region us-east-1
```

### 3. Build and push image

```bash
./scripts/deploy.sh --env staging --tag $(git rev-parse --short HEAD)
```

### 4. Deploy App Runner

```bash
aws cloudformation deploy \
  --template-file infra/cloudformation/app-runner.yml \
  --stack-name webapp-api-staging \
  --parameter-overrides file://infra/cloudformation/parameters/staging.json \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## Updating the deployment

Re-run `deploy.sh` — it builds, pushes the new image, and updates the CloudFormation stack in one step.
