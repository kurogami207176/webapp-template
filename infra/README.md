# Infrastructure (Terraform)

This directory contains Terraform configuration for deploying to AWS (ECS Fargate + RDS PostgreSQL).

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with appropriate credentials
- An S3 bucket + DynamoDB table for remote state (run `scripts/bootstrap-tf-backend.sh` once)

## Structure

```
infra/
├── modules/          # Reusable Terraform modules
│   ├── ecr-repo/
│   ├── ecs-service/
│   └── rds-postgres/
└── environments/
    ├── staging/
    └── production/
```

## Deploying

```bash
cd infra/environments/staging
terraform init
terraform plan
terraform apply
```

## First-time setup

1. Run `scripts/bootstrap-tf-backend.sh` to create the S3 + DynamoDB backend
2. Update `environments/staging/terraform.tfvars` with your values
3. `terraform init && terraform apply`
