variable "service_name" { type = string }
variable "cluster_arn" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "image" { type = string }
variable "container_port" { type = number; default = 3000 }
variable "cpu" { type = number; default = 256 }
variable "memory" { type = number; default = 512 }
variable "desired_count" { type = number; default = 1 }
variable "aws_region" { type = string }
variable "environment_vars" { type = map(string); default = {} }
variable "secret_arns" { type = list(string); default = [] }
variable "secret_arns_map" { type = map(string); default = {} }
variable "tags" { type = map(string); default = {} }
