variable "project_name"        { type = string }
variable "environment"         { type = string }
variable "vpc_id"              { type = string }
variable "vpc_cidr"            { type = string }
variable "aws_region"          { type = string; default = "us-east-1" }
variable "bastion_allowed_cidrs" { type = list(string); default = ["0.0.0.0/0"]; description = "Restrict to operator IPs in production." }
variable "common_tags"         { type = map(string); default = {} }
variable "name_prefix"         { type = string }