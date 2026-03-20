variable "project_name"          { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_ids"     { type = list(string) }
variable "private_app_subnet_ids" { type = list(string) }
variable "alb_security_group_id" { type = string }
variable "internal_alb_sg_id"    { type = string }
variable "common_tags"           { type = map(string); default = {} }
variable "name_prefix"           { type = string }