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
SKIP_DNS="false"

# ---- parse args -------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --env)       ENV="$2";       shift 2 ;;
    --region)    REGION="$2";    shift 2 ;;
    --app-name)  APP_NAME="$2";  shift 2 ;;
    --skip-dns)  SKIP_DNS="true"; shift 1 ;;
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
DNS_STACK="${APP_NAME}-dns-${ENV}"
CF_DIR="$(cd "$(dirname "$0")/../cf" && pwd)"

# ---- load tags from cf/tags.json --------------------------------------------
TAGS_FILE="${CF_DIR}/tags.json"
if [[ ! -f "${TAGS_FILE}" ]]; then
  echo "ERROR: ${TAGS_FILE} not found." >&2; exit 1
fi
# Convert [{"Key":"k","Value":"v"},...] → "k=v k2=v2 ..." for --tags
CF_TAGS=$(jq -r '.[] | "\(.Key)=\(.Value)"' "${TAGS_FILE}" | tr '\n' ' ')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Deploying infrastructure — env: ${ENV}  region: ${REGION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ---- validate templates first -----------------------------------------------
echo ""
echo "▶ Validating CloudFormation templates…"
TEMPLATES_TO_VALIDATE="ecr.yml network.yml ecs.yml"
[[ "${SKIP_DNS}" == "false" ]] && TEMPLATES_TO_VALIDATE="${TEMPLATES_TO_VALIDATE} dns.yml"
for tpl in ${TEMPLATES_TO_VALIDATE}; do
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
  --tags ${CF_TAGS} \
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
  --tags ${CF_TAGS} \
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
      "CreateHttpListener=$([ "${SKIP_DNS}" == "true" ] && echo true || echo false)" \
  --tags ${CF_TAGS} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${REGION}" \
  --no-fail-on-empty-changeset
echo "  ✓ ECS stack deployed"

ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name "${ECS_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`AlbDnsName`].OutputValue' \
  --output text)

# ---- 4. DNS (optional) ------------------------------------------------------
APP_URL="http://${ALB_DNS}"
if [[ "${SKIP_DNS}" == "false" ]]; then
  echo ""
  echo "▶ Stack 4/4 — DNS + TLS (${DNS_STACK})"
  echo "  Note: ACM certificate validation can take 2–5 minutes…"
  aws cloudformation deploy \
    --template-file "${CF_DIR}/dns.yml" \
    --stack-name "${DNS_STACK}" \
    --parameter-overrides \
        "AppName=${APP_NAME}" \
        "Environment=${ENV}" \
        "EcsStackName=${ECS_STACK}" \
    --tags ${CF_TAGS} \
    --capabilities CAPABILITY_IAM \
    --region "${REGION}" \
    --no-fail-on-empty-changeset

  APP_URL=$(aws cloudformation describe-stacks \
    --stack-name "${DNS_STACK}" \
    --region "${REGION}" \
    --query 'Stacks[0].Outputs[?OutputKey==`AppUrl`].OutputValue' \
    --output text)
  echo "  ✓ DNS stack deployed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅  Infrastructure ready"
echo "    ECR URI : ${ECR_URI}"
echo "    App URL : ${APP_URL}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Push a Docker image:  ./bin/push-image.sh --tag latest"
echo "  2. Force a new deploy:   ./bin/deploy-app.sh --env ${ENV}"
