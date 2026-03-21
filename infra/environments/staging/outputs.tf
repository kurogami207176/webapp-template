output "ecr_repository_url" {
  description = "ECR repository URL for the API image"
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}
