#!/usr/bin/env bash
set -euo pipefail

ENV=""
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --env) ENV="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$ENV" ]] && { echo "Usage: $0 --env <staging|production> --tag <tag>"; exit 1; }
[[ -z "$TAG" ]] && { echo "--tag is required"; exit 1; }
[[ "$ENV" != "staging" && "$ENV" != "production" ]] && { echo "--env must be staging or production"; exit 1; }

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID required}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/webapp-api"

echo "Deploying tag=${TAG} to env=${ENV}"

# Login to ECR
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build and push
STABLE_TAG=$( [[ "$ENV" == "production" ]] && echo "stable" || echo "latest" )
docker build -f api/Dockerfile \
  -t "${ECR_REPO}:${TAG}" \
  -t "${ECR_REPO}:${STABLE_TAG}" \
  api/
docker push "${ECR_REPO}:${TAG}"
docker push "${ECR_REPO}:${STABLE_TAG}"

# Update CloudFormation stack
aws cloudformation deploy \
  --template-file infra/cloudformation/app-runner.yml \
  --stack-name "webapp-api-${ENV}" \
  --parameter-overrides \
    "file://infra/cloudformation/parameters/${ENV}.json" \
    "ImageTag=${TAG}" \
  --capabilities CAPABILITY_IAM \
  --region "$AWS_REGION"

echo "Deployment complete!"
echo "Check status: aws apprunner list-services --region $AWS_REGION"
