#!/usr/bin/env bash
# bin/deploy-app.sh
# ---------------------------------------------------------------------------
# Force a new ECS deployment (picks up the latest image already in ECR).
# Use after pushing a new image with bin/push-image.sh.
#
# Usage:
#   ./bin/deploy-app.sh [--env staging|production] [--region us-east-1] [--tag v1.2.3]
# ---------------------------------------------------------------------------
set -euo pipefail

ENV="production"
REGION="us-east-1"
APP_NAME="webapp-template"
TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --env)    ENV="$2";    shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --tag)    TAG="$2";    shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

ECS_STACK="${APP_NAME}-ecs-${ENV}"
ECR_STACK="${APP_NAME}-ecr"
CF_DIR="$(cd "$(dirname "$0")/../cf" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deploying app — env: ${ENV}  region: ${REGION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# If a tag was supplied, update the CloudFormation stack (updates task def)
if [[ -n "${TAG}" ]]; then
  echo ""
  echo "▶ Updating ECS stack with ImageTag=${TAG}…"
  NETWORK_STACK="${APP_NAME}-network-${ENV}"
  aws cloudformation deploy \
    --template-file "${CF_DIR}/ecs.yml" \
    --stack-name "${ECS_STACK}" \
    --parameter-overrides \
        "AppName=${APP_NAME}" \
        "Environment=${ENV}" \
        "NetworkStackName=${NETWORK_STACK}" \
        "EcrStackName=${ECR_STACK}" \
        "ImageTag=${TAG}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "${REGION}" \
    --no-fail-on-empty-changeset
fi

# Resolve cluster + service names
CLUSTER=$(aws cloudformation describe-stacks \
  --stack-name "${ECS_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' \
  --output text)

SERVICE=$(aws cloudformation describe-stacks \
  --stack-name "${ECS_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`ServiceName`].OutputValue' \
  --output text)

echo ""
echo "▶ Forcing new deployment on ${CLUSTER}/${SERVICE}…"
aws ecs update-service \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --force-new-deployment \
  --region "${REGION}" \
  --output text > /dev/null

echo ""
echo "▶ Waiting for service to stabilise (this may take ~3 min)…"
aws ecs wait services-stable \
  --cluster "${CLUSTER}" \
  --services "${SERVICE}" \
  --region "${REGION}"

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name "${ECS_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`AlbDnsName`].OutputValue' \
  --output text)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅  Deployment complete"
echo "    App URL: http://${ALB_DNS}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
