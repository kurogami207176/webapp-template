#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/deploy.sh --env staging --tag abc1234
ENV=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --env) ENV="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

[[ -z "$ENV" ]] && { echo "Usage: $0 --env <staging|production> --tag <git-sha>"; exit 1; }
[[ -z "$TAG" ]] && { echo "--tag is required"; exit 1; }
[[ "$ENV" != "staging" && "$ENV" != "production" ]] && { echo "--env must be staging or production"; exit 1; }

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID env var required}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/webapp-api"
ECS_CLUSTER="webapp-${ENV}"
ECS_SERVICE="webapp-api-${ENV}"

echo "Deploying tag=${TAG} to env=${ENV}"

# Login to ECR
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build and push
docker build -t "${ECR_REPO}:${TAG}" -t "${ECR_REPO}:latest" \
  -f apps/api/Dockerfile .
docker push "${ECR_REPO}:${TAG}"
docker push "${ECR_REPO}:latest"

# Update ECS service
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --force-new-deployment \
  --region "$AWS_REGION"

# Wait for stability
echo "Waiting for deployment to stabilize..."
aws ecs wait services-stable \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --region "$AWS_REGION"

echo "Deployment complete!"
