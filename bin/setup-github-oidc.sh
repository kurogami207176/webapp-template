#!/usr/bin/env bash
# bin/setup-github-oidc.sh
# ---------------------------------------------------------------------------
# Creates the GitHub OIDC provider and deploy role (run once per account).
#
# Usage:
#   ./bin/setup-github-oidc.sh --github-org <org> --github-repo <repo> [--region us-east-1]
# ---------------------------------------------------------------------------
set -euo pipefail

REGION="us-east-1"
APP_NAME="webapp-template"
GITHUB_ORG=""
GITHUB_REPO=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --github-org)  GITHUB_ORG="$2";  shift 2 ;;
    --github-repo) GITHUB_REPO="$2"; shift 2 ;;
    --region)      REGION="$2";      shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "${GITHUB_ORG}" || -z "${GITHUB_REPO}" ]]; then
  echo "Usage: $0 --github-org <org> --github-repo <repo> [--region <region>]" >&2
  exit 1
fi

ECR_STACK="${APP_NAME}-ecr"
OIDC_STACK="${APP_NAME}-github-oidc"
CF_DIR="$(cd "$(dirname "$0")/../cf" && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Setting up GitHub OIDC for ${GITHUB_ORG}/${GITHUB_REPO}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "▶ Validating template…"
aws cloudformation validate-template \
  --template-body "file://${CF_DIR}/iam-github-oidc.yml" \
  --region "${REGION}" \
  --output text > /dev/null
echo "  ✓ Template valid"

echo ""
echo "▶ Deploying OIDC stack (${OIDC_STACK})…"
aws cloudformation deploy \
  --template-file "${CF_DIR}/iam-github-oidc.yml" \
  --stack-name "${OIDC_STACK}" \
  --parameter-overrides \
      "GitHubOrg=${GITHUB_ORG}" \
      "GitHubRepo=${GITHUB_REPO}" \
      "AppName=${APP_NAME}" \
      "EcrStackName=${ECR_STACK}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "${REGION}" \
  --no-fail-on-empty-changeset

ROLE_ARN=$(aws cloudformation describe-stacks \
  --stack-name "${OIDC_STACK}" \
  --region "${REGION}" \
  --query 'Stacks[0].Outputs[?OutputKey==`DeployRoleArn`].OutputValue' \
  --output text)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✅  OIDC setup complete"
echo ""
echo " Add the following to your GitHub repository secrets:"
echo ""
echo "   AWS_DEPLOY_ROLE_ARN = ${ROLE_ARN}"
echo ""
echo " And these repository variables:"
echo "   AWS_REGION          = ${REGION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
