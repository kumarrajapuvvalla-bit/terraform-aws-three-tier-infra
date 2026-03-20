terraform {
  backend "s3" {
    bucket         = "terraform-state-three-tier-infra"
    key            = "three-tier-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Bootstrap (run once before terraform init):
# aws s3api create-bucket --bucket terraform-state-three-tier-infra --region us-east-1
# aws s3api put-bucket-versioning --bucket terraform-state-three-tier-infra --versioning-configuration Status=Enabled
# aws s3api put-bucket-encryption --bucket terraform-state-three-tier-infra --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1