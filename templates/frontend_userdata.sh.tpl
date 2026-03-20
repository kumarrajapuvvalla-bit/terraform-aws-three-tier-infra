#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

dnf update -y
dnf install -y docker amazon-cloudwatch-agent

systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

docker run -d   --name frontend   --restart unless-stopped   -p 80:80   -e ENVIRONMENT=${environment}   -e PROJECT=${project}   nginx:alpine

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl   -a fetch-config -m ec2 -s