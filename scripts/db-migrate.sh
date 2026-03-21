#!/usr/bin/env bash
set -euo pipefail

# Runs Prisma migrations via an ephemeral ECS task (no direct DB access needed from CI)
ENV="${1:?Usage: $0 <staging|production>}"

AWS_REGION="${AWS_REGION:-us-east-1}"
ECS_CLUSTER="webapp-${ENV}"
TASK_DEFINITION="webapp-api-${ENV}"
SUBNET_ID="${ECS_SUBNET_ID:?ECS_SUBNET_ID required}"
SECURITY_GROUP_ID="${ECS_SECURITY_GROUP_ID:?ECS_SECURITY_GROUP_ID required}"

echo "Running migrations in ${ENV}..."

TASK_ARN=$(aws ecs run-task \
  --cluster "$ECS_CLUSTER" \
  --task-definition "$TASK_DEFINITION" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID]}" \
  --overrides '{"containerOverrides":[{"name":"api","command":["npx","prisma","migrate","deploy"]}]}' \
  --query 'tasks[0].taskArn' \
  --output text \
  --region "$AWS_REGION")

echo "Migration task started: $TASK_ARN"

aws ecs wait tasks-stopped \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN" \
  --region "$AWS_REGION"

EXIT_CODE=$(aws ecs describe-tasks \
  --cluster "$ECS_CLUSTER" \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text \
  --region "$AWS_REGION")

if [[ "$EXIT_CODE" != "0" ]]; then
  echo "Migration failed with exit code $EXIT_CODE"
  exit 1
fi

echo "Migrations applied successfully!"
