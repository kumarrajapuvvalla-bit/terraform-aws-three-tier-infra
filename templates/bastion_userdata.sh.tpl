#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

dnf update -y
dnf install -y amazon-cloudwatch-agent awscli postgresql15 amazon-ssm-agent

sed -i 's/#PermitRootLogin yes/PermitRootLogin no/'         /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/'              /etc/ssh/sshd_config
echo 'MaxAuthTries 3'          >> /etc/ssh/sshd_config
echo 'ClientAliveInterval 300' >> /etc/ssh/sshd_config
echo 'ClientAliveCountMax 2'   >> /etc/ssh/sshd_config
systemctl restart sshd

systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl   -a fetch-config -m ec2 -s

echo "Bastion ready. Region: ${aws_region} | Env: ${environment}"