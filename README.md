# terraform-aws-three-tier-infra

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-~%3E5.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-grade, three-tier AWS infrastructure built with Terraform. Designed as a flagship portfolio project demonstrating real-world IaC engineering across networking, compute, data, security, and observability.

---

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │          Tier 1 — Public Subnets                 │   │
│  │  AZ1: 10.0.1.0/24      AZ2: 10.0.2.0/24         │   │
│  │  ┌──────────┐          ┌──────────────────────┐  │   │
│  │  │ NAT GW 1 │          │ NAT GW 2 │  Bastion  │  │   │
│  │  └──────────┘          └──────────────────────┘  │   │
│  │  ┌──────────────────────────────────────────┐    │   │
│  │  │     External Application Load Balancer   │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────┘   │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │          Tier 2 — Private App Subnets            │   │
│  │  AZ1: 10.0.11.0/24     AZ2: 10.0.12.0/24        │   │
│  │  ┌────────────┐        ┌────────────┐            │   │
│  │  │ Frontend   │        │ Frontend   │            │   │
│  │  │ ASG (Nginx)│        │ ASG (Nginx)│            │   │
│  │  └────────────┘        └────────────┘            │   │
│  │  ┌──────────────────────────────────────────┐    │   │
│  │  │       Internal Application Load Balancer  │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  │  ┌────────────┐        ┌────────────┐            │   │
│  │  │ Backend    │        │ Backend    │            │   │
│  │  │ ASG (Flask)│        │ ASG (Flask)│            │   │
│  │  └────────────┘        └────────────┘            │   │
│  └──────────────────────────────────────────────────┘   │
│                         │                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │          Tier 3 — Private Data Subnets           │   │
│  │  AZ1: 10.0.21.0/24     AZ2: 10.0.22.0/24        │   │
│  │  ┌────────────┐        ┌────────────┐            │   │
│  │  │ RDS Primary│        │ RDS Replica│            │   │
│  │  │ PostgreSQL │        │ PostgreSQL │            │   │
│  │  └────────────┘        └────────────┘            │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
terraform-aws-three-tier-infra/
├── main.tf                          # Root module — wires all child modules
├── variables.tf                     # All input variables with validation
├── outputs.tf                       # Root outputs (sensitive where needed)
├── versions.tf                      # Terraform + provider version pins
├── backend.tf                       # S3 remote state + DynamoDB locking
├── terraform.tfvars.example         # Template for your tfvars file
├── .gitignore                       # Excludes state, secrets, .terraform/
├── modules/
│   ├── networking/                  # VPC, subnets, IGW, NAT GWs, routes, flow logs
│   ├── security/                    # Security groups, IAM roles + instance profiles
│   ├── compute/                     # Launch Templates, ASGs, Bastion Host, scaling policies
│   ├── load_balancer/               # External ALB, Internal ALB, target groups, listeners
│   ├── database/                    # RDS primary + replica, subnet group, parameter group
│   ├── monitoring/                  # CloudWatch log groups, alarms, SNS, dashboard
│   └── secrets/                     # Secrets Manager (generated DB password)
├── environments/
│   ├── dev/                         # Dev: t3.micro, no NAT, 1 instance, cheap
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/                        # Prod: t3.medium, NAT GWs, Multi-AZ, deletion protection
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── templates/
│   ├── frontend_userdata.sh.tpl     # Docker + Nginx install
│   ├── backend_userdata.sh.tpl      # Docker + Flask install, pulls DB creds from Secrets Manager
│   └── bastion_userdata.sh.tpl      # SSH hardening + SSM agent
├── CHANGELOG.md
└── LICENSE
```

---

## Terraform Concepts Demonstrated

| Concept | Where Used | Why |
|---|---|---|
| `count` | Subnets, NAT Gateways, EIPs | Create N resources across AZs from a list |
| `for_each` | Security group ingress rules (dynamic blocks) | Iterate over a rule map — extensible without code duplication |
| `depends_on` | Private route tables → NAT Gateways | Explicit ordering where Terraform can't infer dependency |
| `lifecycle.create_before_destroy` | Launch Templates, ASGs, SGs | Zero-downtime updates |
| `lifecycle.prevent_destroy` | RDS primary instance | Guard against accidental `terraform destroy` data loss |
| `lifecycle.ignore_changes` | EC2 AMI, ASG desired_capacity | Allow external changes (patch automation, autoscaling) without drift |
| Provider alias | `aws.secondary` (us-west-2) | Multi-region readiness |
| `locals` | `common_tags`, `name_prefix` | Single source of truth for tags and naming |
| Data sources | `aws_ami`, `aws_availability_zones`, `aws_caller_identity`, `aws_secretsmanager_secret_version` | Dynamic lookups at plan time |
| Dynamic blocks | Security group ingress/egress | Rule maps rendered without repetitive HCL blocks |
| Conditional expressions | `enable_nat_gateway ? ... : 0`, `environment == "prod" ? true : false` | Environment-aware resource provisioning |
| `templatefile()` | EC2 user data scripts | Keeps bash scripts separate from HCL; injectable variables |
| `for` expressions | Tag maps in ASG dynamic blocks | Build key-value structures from module outputs |
| `terraform_remote_state` | Referenced (commented) in dev environment | Cross-stack output consumption pattern |
| Input validation blocks | CIDR, environment, instance type, AZ count | Catch misconfigurations before any AWS API call |
| `sensitive = true` | DB password variable, DB endpoint output | Redacted from CLI and logs |
| `moved` block | Commented example in `main.tf` | Refactoring resources without destroy/recreate |
| `terraform.workspace` | `name_prefix`, `common_tags` | Workspace-aware naming for state isolation |

---

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with appropriate permissions
- S3 bucket and DynamoDB table for remote state (see bootstrap below)
- An AWS account

---

## Bootstrap Remote State

Run once before your first `terraform init`:

```bash
aws s3api create-bucket \
  --bucket terraform-state-three-tier-infra \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket terraform-state-three-tier-infra \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket terraform-state-three-tier-infra \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## Deployment

### Dev Environment

```bash
cd environments/dev

cp ../../terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Prod Environment

```bash
cd environments/prod

# Set sensitive vars via environment variables — never in tfvars
export TF_VAR_db_username="dbadmin"

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Destroy Safely

```bash
# Dev — straightforward
cd environments/dev
terraform destroy

# Prod — requires disabling prevent_destroy on RDS first
# 1. Set db_deletion_protection = false in terraform.tfvars
# 2. Comment out lifecycle { prevent_destroy = true } in modules/database/main.tf
# 3. terraform apply   (removes deletion protection)
# 4. terraform destroy
```

---

## Security Considerations

- **IMDSv2 enforced** on all EC2 instances (`http_tokens = "required"`)
- **No SSH keys required** — SSM Session Manager is the primary access method
- **Least-privilege security groups** — each tier only accepts traffic from the tier above
- **RDS is never publicly accessible** — data tier has no internet egress route
- **Secrets Manager** for all credentials — no plaintext in tfvars or state
- **S3 state encryption** with AES-256; DynamoDB locking prevents concurrent applies
- **VPC Flow Logs** capture all IP traffic for security audit
- **`prevent_destroy`** on RDS primary prevents accidental data loss

---

## Future Improvements

- Add ACM certificate and HTTPS listener on external ALB
- Configure Secrets Manager rotation Lambda for automatic DB password rotation
- Add WAF (AWS WAF v2) in front of the external ALB
- Implement Route 53 with health checks and failover routing
- Add ElastiCache (Redis) between app and data tiers for caching
- Enable RDS Performance Insights alerting on slow queries
- Add AWS Config rules for continuous compliance checking
- Implement cross-region RDS read replica for DR using the secondary provider alias
- Add GitHub Actions CI pipeline running `terraform fmt`, `validate`, and `tfsec`
- Migrate to EKS for containerised workloads at scale