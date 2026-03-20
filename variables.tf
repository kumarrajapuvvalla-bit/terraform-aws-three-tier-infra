# ============================================================
# variables.tf — Root module input variable declarations
#
# All configurable parameters are declared here with descriptions,
# types, default values, and validation blocks. No hardcoded values
# should appear anywhere else in the root module — everything flows
# through these variables.
#
# Sensitive variables are marked sensitive = true so Terraform masks
# them in plan/apply output. Never commit actual secrets to version
# control — use Secrets Manager or environment variables instead.
# ============================================================

# ---------------------------------------------------------------------------
# General / Global
# ---------------------------------------------------------------------------

variable "project_name" {
  description = "Short, lowercase project identifier used as a name prefix for all resources. Keep it concise — it forms part of resource names."
  type        = string
  default     = "three-tier"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must be 3-24 lowercase alphanumeric characters or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Controls resource sizing, deletion protection, and naming. Must be one of: dev, staging, prod."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Team or individual responsible for this infrastructure. Used in the Owner tag for cost attribution and incident response."
  type        = string
  default     = "platform-engineering"
}

variable "aws_region" {
  description = "Primary AWS region for resource deployment. All resources are deployed here unless explicitly using the secondary provider alias."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier (e.g. us-east-1, eu-west-2)."
  }
}

variable "secondary_region" {
  description = "Secondary AWS region used for the provider alias. Enables cross-region disaster recovery and replication capabilities."
  type        = string
  default     = "us-west-2"
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. Must be a /16 to allow enough address space for all tier subnets across both AZs."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones to deploy into. Exactly two AZs are required for the HA architecture. They must exist in the chosen aws_region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) == 2
    error_message = "Exactly two availability zones must be specified for HA deployment."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ). These subnets host the ALB, NAT Gateways, and Bastion Host."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly two public subnet CIDRs are required (one per AZ)."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application-tier subnets (one per AZ). Hosts frontend and backend EC2 instances."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2
    error_message = "Exactly two private app subnet CIDRs are required (one per AZ)."
  }
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data-tier subnets (one per AZ). Hosts RDS primary and replica instances."
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]

  validation {
    condition     = length(var.private_data_subnet_cidrs) == 2
    error_message = "Exactly two private data subnet CIDRs are required (one per AZ)."
  }
}

variable "enable_nat_gateway" {
  description = "Set to true to provision NAT Gateways (one per AZ for HA). Set to false in dev environments to reduce cost — private instances will lose outbound internet access."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

variable "frontend_instance_type" {
  description = "EC2 instance type for frontend (presentation-tier) instances in the ASG. Must be a valid instance type."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge"], var.frontend_instance_type)
    error_message = "frontend_instance_type must be one of the allowed instance types."
  }
}

variable "backend_instance_type" {
  description = "EC2 instance type for backend (application-tier) API instances in the ASG."
  type        = string
  default     = "t3.small"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large", "m5.large", "m5.xlarge"], var.backend_instance_type)
    error_message = "backend_instance_type must be one of the allowed instance types."
  }
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the Bastion Host. t3.micro is sufficient for jump-box purposes."
  type        = string
  default     = "t3.micro"
}

variable "frontend_min_size" {
  description = "Minimum number of frontend instances in the ASG. Should be >= 2 for production HA."
  type        = number
  default     = 2
}

variable "frontend_max_size" {
  description = "Maximum number of frontend instances the ASG can scale out to under load."
  type        = number
  default     = 6
}

variable "frontend_desired_capacity" {
  description = "Desired number of frontend instances. The ASG will maintain this count under normal load."
  type        = number
  default     = 2
}

variable "backend_min_size" {
  description = "Minimum number of backend API instances in the ASG."
  type        = number
  default     = 2
}

variable "backend_max_size" {
  description = "Maximum number of backend API instances the ASG can scale out to."
  type        = number
  default     = 6
}

variable "backend_desired_capacity" {
  description = "Desired number of backend API instances."
  type        = number
  default     = 2
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair to associate with instances. Used for emergency SSH access via Bastion. Leave empty string to disable key-based SSH."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class for primary and replica. db.t3.medium is the minimum for production workloads."
  type        = string
  default     = "db.t3.medium"

  validation {
    condition     = can(regex("^db\.", var.db_instance_class))
    error_message = "db_instance_class must be a valid RDS instance class starting with 'db.'."
  }
}

variable "db_name" {
  description = "Name of the initial database to create on the RDS instance. Must start with a letter and contain only alphanumeric characters."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,63}$", var.db_name))
    error_message = "db_name must start with a letter and contain only alphanumeric characters or underscores."
  }
}

variable "db_username" {
  description = "Master username for the RDS instance. This is stored in Secrets Manager post-creation."
  type        = string
  default     = "dbadmin"
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username))
    error_message = "db_username must start with a letter and be 1-16 alphanumeric characters."
  }
}

variable "db_engine_version" {
  description = "PostgreSQL engine version for the RDS instance."
  type        = string
  default     = "15.4"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GiB. With autoscaling enabled, this is the minimum."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage autoscaling threshold in GiB. RDS will automatically scale up to this limit."
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS primary. In dev this can be false; in prod it must be true."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection on RDS. Must be disabled before destroying. Set to true in production."
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated RDS backups. Must be between 1-35 days in production."
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 1 && var.db_backup_retention_period <= 35
    error_message = "db_backup_retention_period must be between 1 and 35 days."
  }
}

# ---------------------------------------------------------------------------
# Monitoring
# ---------------------------------------------------------------------------

variable "cloudwatch_retention_days" {
  description = "CloudWatch log group retention in days. Balance between operational visibility and cost."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 180, 365, 400, 545, 731], var.cloudwatch_retention_days)
    error_message = "cloudwatch_retention_days must be a valid CloudWatch retention period."
  }
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm SNS notifications. An opt-in confirmation email will be sent to this address."
  type        = string
  default     = "ops-alerts@example.com"
}

variable "cpu_alarm_threshold" {
  description = "CPU utilisation percentage threshold that triggers scaling alarms. Adjust based on application profiling."
  type        = number
  default     = 75
}
