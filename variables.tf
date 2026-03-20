variable "project_name" {
  description = "Project identifier used as name prefix for all resources."
  type        = string
  default     = "three-tier"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must be 3-24 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Team or individual responsible for this infrastructure."
  type        = string
  default     = "platform-engineering"
}

variable "aws_region" {
  description = "Primary AWS region for all resources."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region (e.g. us-east-1)."
  }
}

variable "secondary_region" {
  description = "Secondary region for the provider alias (DR / multi-region readiness)."
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Exactly two AZs for HA deployment."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones must be specified."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs required."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app-tier subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2
    error_message = "Exactly two private app subnet CIDRs required."
  }
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data-tier subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]

  validation {
    condition     = length(var.private_data_subnet_cidrs) == 2
    error_message = "Exactly two private data subnet CIDRs required."
  }
}

variable "enable_nat_gateway" {
  description = "Provision NAT Gateways (one per AZ). Set false to reduce cost in dev."
  type        = bool
  default     = true
}

variable "frontend_instance_type" {
  description = "EC2 instance type for frontend ASG instances."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge"], var.frontend_instance_type)
    error_message = "Invalid frontend_instance_type."
  }
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend ASG instances."
  type        = string
  default     = "t3.small"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge"], var.backend_instance_type)
    error_message = "Invalid backend_instance_type."
  }
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the Bastion Host."
  type        = string
  default     = "t3.micro"
}

variable "frontend_min_size"         { type = number; default = 2 }
variable "frontend_max_size"         { type = number; default = 6 }
variable "frontend_desired_capacity" { type = number; default = 2 }
variable "backend_min_size"          { type = number; default = 2 }
variable "backend_max_size"          { type = number; default = 6 }
variable "backend_desired_capacity"  { type = number; default = 2 }

variable "key_pair_name" {
  description = "Existing EC2 key pair name. Leave empty to use SSM Session Manager only."
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"

  validation {
    condition     = can(regex("^db\.", var.db_instance_class))
    error_message = "db_instance_class must start with 'db.'."
  }
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username."
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_engine_version"          { type = string; default = "15.4" }
variable "db_allocated_storage"       { type = number; default = 20 }
variable "db_max_allocated_storage"   { type = number; default = 100 }
variable "db_multi_az"                { type = bool;   default = false }
variable "db_deletion_protection"     { type = bool;   default = false }
variable "db_backup_retention_period" { type = number; default = 7 }

variable "cloudwatch_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365], var.cloudwatch_retention_days)
    error_message = "cloudwatch_retention_days must be a valid CloudWatch retention period."
  }
}

variable "alarm_email"         { type = string; default = "ops@example.com" }
variable "cpu_alarm_threshold" { type = number; default = 75 }