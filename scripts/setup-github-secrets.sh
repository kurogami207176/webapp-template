#!/usr/bin/env bash
# Usage: ./scripts/setup-github-secrets.sh <github-repo>
# Example: ./scripts/setup-github-secrets.sh my-new-app
#
# Requires: gh CLI (https://cli.github.com) — brew install gh && gh auth login
#
# This script reads AWS credentials from your local AWS config/environment
# and pushes them as GitHub Actions secrets to the target repo.

set -euo pipefail

# --- Args ---
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <github-repo>"
  echo "  e.g. $0 my-new-app"
  echo "  e.g. $0 myorg/my-new-app  (if under an org)"
  exit 1
fi

REPO="$1"
REGION="${AWS_REGION:-ap-southeast-2}"

# --- Resolve credentials ---
# Prefer explicit env vars, fall back to AWS CLI identity
ACCESS_KEY="${AWS_ACCESS_KEY_ID:-}"
SECRET_KEY="${AWS_SECRET_ACCESS_KEY:-}"
ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"

if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
  echo "AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY not set in environment."
  echo "Enter the github-actions-webapp credentials:"
  read -rp "  Access Key ID:     " ACCESS_KEY
  read -rsp "  Secret Access Key: " SECRET_KEY
  echo
fi

if [[ -z "$ACCOUNT_ID" ]]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
fi

# --- Sanity checks ---
if ! command -v gh &>/dev/null; then
  echo "❌  gh CLI not found. Install it first:"
  echo "    brew install gh && gh auth login"
  exit 1
fi

echo "📦  Setting GitHub Actions secrets on: $REPO"
echo "    Region:     $REGION"
echo "    Account ID: $ACCOUNT_ID"
echo

gh secret set AWS_ACCESS_KEY_ID     --repo "$REPO" --body "$ACCESS_KEY"
gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO" --body "$SECRET_KEY"
gh secret set AWS_REGION            --repo "$REPO" --body "$REGION"
gh secret set AWS_ACCOUNT_ID        --repo "$REPO" --body "$ACCOUNT_ID"

echo
echo "✅  Done! Secrets set on $REPO:"
echo "    AWS_ACCESS_KEY_ID"
echo "    AWS_SECRET_ACCESS_KEY"
echo "    AWS_REGION"
echo "    AWS_ACCOUNT_ID"
