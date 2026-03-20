variable "project_name"              { type = string }
variable "environment"               { type = string }
variable "aws_region"                { type = string }
variable "frontend_asg_name"         { type = string }
variable "backend_asg_name"          { type = string }
variable "external_alb_arn_suffix"   { type = string }
variable "db_instance_identifier"    { type = string }
variable "cloudwatch_retention_days" { type = number; default = 30 }
variable "alarm_email"               { type = string }
variable "cpu_alarm_threshold"       { type = number; default = 75 }
variable "common_tags"               { type = map(string); default = {} }
variable "name_prefix"               { type = string }