# ============================================================
# versions.tf — Terraform and provider version constraints
#
# Pins the Terraform CLI version and AWS provider to known-good
# ranges. Using pessimistic version constraints (~>) ensures we
# automatically pick up patch/minor releases while avoiding
# unexpected breaking changes from major version bumps.
#
# Update these intentionally after reading provider changelogs.
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Primary provider — us-east-1 (default region, overridable via variable)
# ---------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      Repository  = "terraform-aws-three-tier-infra"
    }
  }
}

# ---------------------------------------------------------------------------
# Secondary provider alias — us-west-2 (multi-region readiness)
# Used for cross-region replication, DR, or read replicas when required.
# Reference with: provider = aws.secondary
# ---------------------------------------------------------------------------
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      Repository  = "terraform-aws-three-tier-infra"
    }
  }
}
