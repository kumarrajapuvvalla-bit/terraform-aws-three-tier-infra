# ============================================================
# modules/networking/variables.tf — Networking module inputs
#
# Accepts all configuration required to build the VPC, subnets,
# gateways, and route tables. The caller (root module or environment
# configs) passes values from their own variable declarations.
# ============================================================

variable "project_name" {
  description = "Project identifier used in resource name prefixes."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "List of exactly two AZ names to deploy subnets into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application-tier subnets, one per AZ."
  type        = list(string)
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data-tier subnets, one per AZ."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Controls whether NAT Gateways are provisioned. Set false to save cost in dev."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Map of tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "String prefix prepended to resource names for uniqueness and identification."
  type        = string
}
