#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

dnf update -y
dnf install -y docker amazon-cloudwatch-agent awscli

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

SECRET=$(aws secretsmanager get-secret-value   --secret-id "${db_secret_arn}"   --region "${aws_region}"   --query SecretString   --output text)

DB_USER=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['username'])")
DB_PASS=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
DB_NAME=$(echo $SECRET | python3 -c "import sys,json; print(json.load(sys.stdin)['dbname'])")

docker run -d   --name backend-api   --restart unless-stopped   -p 8080:8080   -e ENVIRONMENT=${environment}   -e PROJECT=${project}   -e DB_HOST=${db_endpoint}   -e DB_USER=$DB_USER   -e DB_PASS=$DB_PASS   -e DB_NAME=$DB_NAME   python:3.11-slim python3 -m http.server 8080