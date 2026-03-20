variable "project_name" { type = string }
variable "environment"  { type = string }
variable "db_name"      { type = string }
variable "db_username"  { type = string; sensitive = true }
variable "common_tags"  { type = map(string); default = {} }
variable "name_prefix"  { type = string }