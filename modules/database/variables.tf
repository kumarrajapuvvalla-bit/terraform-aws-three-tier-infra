variable "project_name"               { type = string }
variable "environment"                { type = string }
variable "db_subnet_ids"              { type = list(string) }
variable "db_security_group_ids"      { type = list(string) }
variable "db_instance_class"          { type = string }
variable "db_name"                    { type = string }
variable "db_username"                { type = string; sensitive = true }
variable "db_password_secret_arn"     { type = string }
variable "db_engine_version"          { type = string; default = "15.4" }
variable "db_allocated_storage"       { type = number; default = 20 }
variable "db_max_allocated_storage"   { type = number; default = 100 }
variable "db_multi_az"                { type = bool;   default = false }
variable "db_deletion_protection"     { type = bool;   default = false }
variable "db_backup_retention_period" { type = number; default = 7 }
variable "common_tags"                { type = map(string); default = {} }
variable "name_prefix"                { type = string }