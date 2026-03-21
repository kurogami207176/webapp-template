#!/usr/bin/env bash
set -euo pipefail

# One-time setup: creates S3 bucket + DynamoDB table for Terraform remote state
AWS_REGION="${AWS_REGION:-us-east-1}"
BUCKET_NAME="${TF_STATE_BUCKET:?TF_STATE_BUCKET env var required}"
LOCK_TABLE="terraform-state-lock"

echo "Creating Terraform state bucket: $BUCKET_NAME"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>/dev/null || true

aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Creating DynamoDB lock table: $LOCK_TABLE"
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" 2>/dev/null || true

echo "Bootstrap complete!"
echo "Add to your backend config: bucket=\"$BUCKET_NAME\" region=\"$AWS_REGION\" dynamodb_table=\"$LOCK_TABLE\""
