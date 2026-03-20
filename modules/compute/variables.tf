variable "project_name"                 { type = string }
variable "environment"                  { type = string }
variable "aws_region"                   { type = string }
variable "public_subnet_ids"            { type = list(string) }
variable "private_app_subnet_ids"       { type = list(string) }
variable "frontend_sg_id"               { type = string }
variable "backend_sg_id"                { type = string }
variable "bastion_sg_id"                { type = string }
variable "frontend_instance_profile_arn" { type = string }
variable "backend_instance_profile_arn"  { type = string }
variable "frontend_target_group_arn"    { type = string }
variable "backend_target_group_arn"     { type = string }
variable "frontend_instance_type"       { type = string }
variable "backend_instance_type"        { type = string }
variable "bastion_instance_type"        { type = string }
variable "frontend_min_size"            { type = number }
variable "frontend_max_size"            { type = number }
variable "frontend_desired_capacity"    { type = number }
variable "backend_min_size"             { type = number }
variable "backend_max_size"             { type = number }
variable "backend_desired_capacity"     { type = number }
variable "key_pair_name"                { type = string; default = "" }
variable "db_secret_arn"                { type = string }
variable "db_endpoint"                  { type = string; sensitive = true }
variable "common_tags"                  { type = map(string); default = {} }
variable "name_prefix"                  { type = string }