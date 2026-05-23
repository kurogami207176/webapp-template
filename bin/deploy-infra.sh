#!/usr/bin/env bash
# bin/deploy-infra.sh
# ---------------------------------------------------------------------------
# Bootstrap all infrastructure stacks (ECR → Network → ECS).
# Run this once to provision; afterwards use bin/deploy-app.sh to release.
#
# Usage:
#   ./bin/deploy-infra.sh [--env staging|production] [--region ap-southeast-2]
# ---------------------------------------------------------------------------
set -euo pipefail

# ---- defaults ---------------------------------------------------------------
ENV="production"
REGION="ap-southeast-2"
APP_NAME=""

# ---- parse args -------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)      ENV="$2";      shift 2 ;;
    --region)   REGION="$2";   shift 2 ;;
    --app-name) APP_NAME="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ---- derive APP_NAME from git remote if not supplied ------------------------
if [[ -z "${APP_NAME}" ]]; then
  APP_NAME=$(git remote get-url origin 2>/dev/null \
    | sed 's|.*[:/]\([^/]*\)\.git$|\1|; s|.*[:/]\([^/]*\)$|\1|')
  if [[ -z "${APP_NAME}" ]]; then
    echo "ERROR: could not derive app name from git remote. Pass --app-name <name>." >&2
    exit 1
  fi
  echo "▶ Derived APP_NAME from git remote: ${APP_NAME}"
fi

# ---- derived names ----------------------------------------------------------
ECR_STACK="${APP_NAME}-ecr"
NETWORK_STACK="${APP_NAME}-network-${ENV}"
ECS_STACK="${APP_NAME}-ecs-${ENV}"
CF_DIR="$(cd "$(dirname "$0")/../cf" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deploying infrastructure — env: ${ENV}  region: ${REGION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---- validate templates first -----------------------------------------------
echo ""
echo "▶ Validating CloudFormation templates…"
for tpl in ecr.yml network.yml ecs.yml; do
  echo "  → ${tpl}"
  aws cloudformation validate-template \
    --template-body "file://${CF_DIR}/${tpl}" \
    --region "${REGION}" \
    --output text > /dev/null
done
echo "  ✓ All templates valid"

# ---- 1. ECR -----------------------------------------------------------------
echo ""
echo "▶ Stack 1/3 — ECR (${ECR_STACK})"
aws cloudformation deploy \
  --template-file "${CF_DIR}/ecr.yml" \
  --stack-name "${ECR_STACK}" \
  --parameter-overrides \
      "AppName=${APP_NAME}" \
      "Environment=${ENV}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${REGION}" \
  --no-fail-on-empty-changeset

ECR_URI=$(aws cloudformation describe-stacks \
  --stack-name "${ECR_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`RepositoryUri`].OutputValue' \
  --output text)
echo "  ✓ ECR URI: ${ECR_URI}"

# ---- 2. Network -------------------------------------------------------------
echo ""
echo "▶ Stack 2/3 — Network (${NETWORK_STACK})"
aws cloudformation deploy \
  --template-file "${CF_DIR}/network.yml" \
  --stack-name "${NETWORK_STACK}" \
  --parameter-overrides \
      "AppName=${APP_NAME}" \
      "Environment=${ENV}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${REGION}" \
  --no-fail-on-empty-changeset
echo "  ✓ Network stack deployed"

# ---- 3. ECS -----------------------------------------------------------------
echo ""
echo "▶ Stack 3/3 — ECS (${ECS_STACK})"
aws cloudformation deploy \
  --template-file "${CF_DIR}/ecs.yml" \
  --stack-name "${ECS_STACK}" \
  --parameter-overrides \
      "AppName=${APP_NAME}" \
      "Environment=${ENV}" \
      "NetworkStackName=${NETWORK_STACK}" \
      "EcrStackName=${ECR_STACK}" \
      "ImageTag=latest" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${REGION}" \
  --no-fail-on-empty-changeset

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name "${ECS_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`AlbDnsName`].OutputValue' \
  --output text)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅  Infrastructure ready"
echo "    ECR URI : ${ECR_URI}"
echo "    App URL : http://${ALB_DNS}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Push a Docker image:  ./bin/push-image.sh --tag latest"
echo "  2. Force a new deploy:   ./bin/deploy-app.sh --env ${ENV}"
