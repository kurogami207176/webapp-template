terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket         = "REPLACE_WITH_YOUR_STATE_BUCKET"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  env         = "staging"
  app_name    = "webapp"
  common_tags = {
    Environment = local.env
    App         = local.app_name
    ManagedBy   = "terraform"
  }
}

module "ecr" {
  source = "../../modules/ecr-repo"
  name   = "${local.app_name}-api"
  tags   = local.common_tags
}

module "rds" {
  source                     = "../../modules/rds-postgres"
  identifier                 = "${local.app_name}-${local.env}"
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.private_subnet_ids
  allowed_security_group_ids = [module.ecs.task_security_group_id]
  tags                       = local.common_tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.app_name}-${local.env}"
  tags = local.common_tags
}

module "ecs" {
  source         = "../../modules/ecs-service"
  service_name   = "${local.app_name}-api-${local.env}"
  cluster_arn    = aws_ecs_cluster.this.arn
  vpc_id         = var.vpc_id
  subnet_ids     = var.private_subnet_ids
  image          = "${module.ecr.repository_url}:latest"
  aws_region     = var.aws_region
  desired_count  = 1

  environment_vars = {
    NODE_ENV   = "production"
    PORT       = "3000"
    LOG_LEVEL  = "info"
  }

  secret_arns = [module.rds.db_password_secret_arn]
  secret_arns_map = {
    DB_PASSWORD = module.rds.db_password_secret_arn
  }

  tags = local.common_tags
}
