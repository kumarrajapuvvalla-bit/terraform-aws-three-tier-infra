# ============================================================
# main.tf — Root module orchestration
#
# This is the entry point for the Terraform configuration. It
# instantiates all child modules and wires their inputs/outputs
# together to form the complete three-tier architecture.
#
# Dependency flow:
#   networking → security → secrets → compute → load_balancer
#                                              → database
#                                              → monitoring
#
# Use terraform.workspace to isolate state between environments
# when running from the root module directly (dev/prod workspaces).
# For proper environment isolation prefer the environments/ configs.
# ============================================================

# ---------------------------------------------------------------------------
# Local values — common tags and computed name prefixes
# ---------------------------------------------------------------------------

locals {
  # Canonical name prefix applied to every resource for easy identification
  # in the AWS console. Includes workspace to differentiate dev vs prod when
  # applying directly from root rather than the environments/ directories.
  name_prefix = "${var.project_name}-${var.environment}-${terraform.workspace == "default" ? "" : "${terraform.workspace}-"}"

  # Single source of truth for tags applied to every resource.
  # Modules merge these into their own resource tags using merge().
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Workspace   = terraform.workspace
  }

  # Compute a map of AZ index → subnet CIDR for use with for_each in modules
  public_subnet_map = {
    for idx, cidr in var.public_subnet_cidrs :
    var.availability_zones[idx] => cidr
  }

  private_app_subnet_map = {
    for idx, cidr in var.private_app_subnet_cidrs :
    var.availability_zones[idx] => cidr
  }

  private_data_subnet_map = {
    for idx, cidr in var.private_data_subnet_cidrs :
    var.availability_zones[idx] => cidr
  }
}

# ---------------------------------------------------------------------------
# Module: Networking (Tier 1 + backbone)
# Creates: VPC, IGW, public/private subnets, NAT Gateways, route tables
# ---------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  project_name              = var.project_name
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  availability_zones        = var.availability_zones
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  enable_nat_gateway        = var.enable_nat_gateway
  common_tags               = local.common_tags
  name_prefix               = local.name_prefix
}

# ---------------------------------------------------------------------------
# Module: Security (Security Groups + IAM)
# Creates: Per-tier security groups, IAM roles, instance profiles
# ---------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = var.vpc_cidr
  common_tags  = local.common_tags
  name_prefix  = local.name_prefix

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Module: Secrets (Secrets Manager)
# Creates: DB credential secret, rotation placeholder
# ---------------------------------------------------------------------------

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment
  db_name      = var.db_name
  db_username  = var.db_username
  common_tags  = local.common_tags
  name_prefix  = local.name_prefix

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Module: Database (Tier 3)
# Creates: RDS PostgreSQL primary + read replica, subnet group, parameter group
# ---------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  project_name               = var.project_name
  environment                = var.environment
  db_subnet_ids              = module.networking.private_data_subnet_ids
  db_security_group_ids      = [module.security.rds_security_group_id]
  db_instance_class          = var.db_instance_class
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password_secret_arn     = module.secrets.db_secret_arn
  db_engine_version          = var.db_engine_version
  db_allocated_storage       = var.db_allocated_storage
  db_max_allocated_storage   = var.db_max_allocated_storage
  db_multi_az                = var.db_multi_az
  db_deletion_protection     = var.db_deletion_protection
  db_backup_retention_period = var.db_backup_retention_period
  common_tags                = local.common_tags
  name_prefix                = local.name_prefix

  depends_on = [module.networking, module.security, module.secrets]
}

# ---------------------------------------------------------------------------
# Module: Load Balancer
# Creates: External ALB (public), Internal ALB (private), target groups, listeners
# ---------------------------------------------------------------------------

module "load_balancer" {
  source = "./modules/load_balancer"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = module.networking.vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  alb_security_group_id     = module.security.alb_security_group_id
  internal_alb_sg_id        = module.security.internal_alb_security_group_id
  common_tags               = local.common_tags
  name_prefix               = local.name_prefix

  depends_on = [module.networking, module.security]
}

# ---------------------------------------------------------------------------
# Module: Compute (Tiers 1 & 2)
# Creates: Launch Templates, ASGs for frontend + backend, Bastion Host
# ---------------------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  public_subnet_ids             = module.networking.public_subnet_ids
  private_app_subnet_ids        = module.networking.private_app_subnet_ids
  frontend_sg_id                = module.security.frontend_security_group_id
  backend_sg_id                 = module.security.backend_security_group_id
  bastion_sg_id                 = module.security.bastion_security_group_id
  frontend_instance_profile_arn = module.security.frontend_instance_profile_arn
  backend_instance_profile_arn  = module.security.backend_instance_profile_arn
  frontend_target_group_arn     = module.load_balancer.frontend_target_group_arn
  backend_target_group_arn      = module.load_balancer.backend_target_group_arn
  frontend_instance_type        = var.frontend_instance_type
  backend_instance_type         = var.backend_instance_type
  bastion_instance_type         = var.bastion_instance_type
  frontend_min_size             = var.frontend_min_size
  frontend_max_size             = var.frontend_max_size
  frontend_desired_capacity     = var.frontend_desired_capacity
  backend_min_size              = var.backend_min_size
  backend_max_size              = var.backend_max_size
  backend_desired_capacity      = var.backend_desired_capacity
  key_pair_name                 = var.key_pair_name
  db_secret_arn                 = module.secrets.db_secret_arn
  db_endpoint                   = module.database.db_endpoint
  common_tags                   = local.common_tags
  name_prefix                   = local.name_prefix

  depends_on = [module.networking, module.security, module.load_balancer, module.database]
}

# ---------------------------------------------------------------------------
# Module: Monitoring (CloudWatch)
# Creates: Log groups, metric alarms, dashboard, SNS topic
# ---------------------------------------------------------------------------

module "monitoring" {
  source = "./modules/monitoring"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  frontend_asg_name         = module.compute.frontend_asg_name
  backend_asg_name          = module.compute.backend_asg_name
  external_alb_arn_suffix   = module.load_balancer.external_alb_arn_suffix
  db_instance_identifier    = module.database.db_instance_identifier
  cloudwatch_retention_days = var.cloudwatch_retention_days
  alarm_email               = var.alarm_email
  cpu_alarm_threshold       = var.cpu_alarm_threshold
  common_tags               = local.common_tags
  name_prefix               = local.name_prefix

  depends_on = [module.compute, module.load_balancer, module.database]
}

# ---------------------------------------------------------------------------
# moved block — demonstrates resource refactoring tracking
# If a resource is renamed/moved, this prevents destroy+recreate.
# Example: previously bastion was a standalone resource, now in compute module.
# ---------------------------------------------------------------------------
# moved {
#   from = aws_instance.bastion
#   to   = module.compute.aws_instance.bastion
# }
