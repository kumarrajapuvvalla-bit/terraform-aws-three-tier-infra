# ============================================================
# backend.tf — Remote state configuration
#
# Stores Terraform state in S3 with DynamoDB-based state locking.
# This prevents concurrent applies from corrupting state and gives
# us a versioned, encrypted audit trail of all infrastructure changes.
#
# BOOTSTRAP INSTRUCTIONS (run once before first terraform init):
#   1. Create the S3 bucket:
#      aws s3api create-bucket \
#        --bucket <your-state-bucket-name> \
#        --region us-east-1
#
#   2. Enable versioning (required for state history):
#      aws s3api put-bucket-versioning \
#        --bucket <your-state-bucket-name> \
#        --versioning-configuration Status=Enabled
#
#   3. Enable server-side encryption:
#      aws s3api put-bucket-encryption \
#        --bucket <your-state-bucket-name> \
#        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
#   4. Block all public access:
#      aws s3api put-public-access-block \
#        --bucket <your-state-bucket-name> \
#        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#
#   5. Create the DynamoDB lock table:
#      aws dynamodb create-table \
#        --table-name terraform-state-lock \
#        --attribute-definitions AttributeName=LockID,AttributeType=S \
#        --key-schema AttributeName=LockID,KeyType=HASH \
#        --billing-mode PAY_PER_REQUEST \
#        --region us-east-1
#
# Replace placeholder values with your actual bucket name and AWS account details.
# ============================================================

terraform {
  backend "s3" {
    # S3 bucket for state storage — must exist before terraform init
    bucket = "terraform-state-three-tier-infra"

    # State file path — uses workspace-aware key so dev/prod are isolated
    key = "three-tier-infra/terraform.tfstate"

    region = "us-east-1"

    # DynamoDB table for state locking — prevents concurrent modifications
    dynamodb_table = "terraform-state-lock"

    # Server-side encryption at rest using AES-256
    encrypt = true

    # Profile to use from ~/.aws/credentials (override via AWS_PROFILE env var)
    # profile = "your-aws-profile"
  }
}
