variable "identifier" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" { type = list(string) }
variable "db_name" { type = string; default = "webapp" }
variable "db_username" { type = string; default = "webapp" }
variable "instance_class" { type = string; default = "db.t3.micro" }
variable "allocated_storage" { type = number; default = 20 }
variable "multi_az" { type = bool; default = false }
variable "tags" { type = map(string); default = {} }
