# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] - 2026-03-20

### Added
- Three-tier AWS architecture: VPC, public/private subnets across 2 AZs
- Internet Gateway, NAT Gateways (one per AZ, conditional), route tables
- VPC Flow Logs to CloudWatch
- Security Groups with least-privilege rules using dynamic blocks
- IAM roles and instance profiles for frontend, backend, and Bastion
- External ALB (internet-facing) and Internal ALB with target groups and listeners
- Frontend ASG with Launch Template (Nginx Docker container)
- Backend ASG with Launch Template (Python/Flask Docker container)
- Bastion Host with SSH hardening and SSM Session Manager
- Auto Scaling policies for CPU-based scale-out and scale-in
- RDS PostgreSQL primary with `prevent_destroy` lifecycle guard
- RDS read replica in AZ2 for read offload and DR
- Custom RDS parameter group with slow query logging
- AWS Secrets Manager for DB credentials (random generated password)
- CloudWatch log groups for frontend, backend, Bastion, and RDS
- CloudWatch alarms: CPU (frontend/backend), ALB 5xx, RDS CPU, RDS storage
- SNS topic with email subscription for alarm routing
- CloudWatch operational dashboard with 4 metric widgets
- `environments/dev` — cost-optimised (t3.micro, no NAT, min 1 instance)
- `environments/prod` — HA config (t3.medium, Multi-AZ RDS, NAT GWs, deletion protection)
- `terraform.tfvars.example` with all variable placeholders documented
- `.gitignore` covering state files, secrets, IDE artefacts
- `templates/` with three user data scripts rendered via `templatefile()`
- Full Terraform concepts: count, for_each, depends_on, lifecycle rules,
  dynamic blocks, locals, data sources, conditional expressions,
  input validation, sensitive variables, for expressions, provider aliases,
  terraform.workspace, moved block (commented reference)