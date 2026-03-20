locals {
  alb_ingress_rules = {
    http  = { from_port = 80,  to_port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTP from internet" }
    https = { from_port = 443, to_port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "HTTPS from internet" }
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}alb-sg"
  description = "External ALB — allows HTTP/HTTPS from internet."
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.alb_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Outbound to VPC only"
  }

  lifecycle { create_before_destroy = true }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}alb-sg", Tier = "public" })
}

resource "aws_security_group" "internal_alb" {
  name        = "${var.name_prefix}internal-alb-sg"
  description = "Internal ALB — accepts traffic from frontend SG only."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
    description     = "API traffic from frontend instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Outbound to VPC only"
  }

  lifecycle { create_before_destroy = true }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}internal-alb-sg", Tier = "private-app" })
}

resource "aws_security_group" "frontend" {
  name        = "${var.name_prefix}frontend-sg"
  description = "Frontend EC2 — accepts traffic from ALB and SSH from Bastion."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from external ALB"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTPS from external ALB"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  lifecycle { create_before_destroy = true }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-sg", Tier = "private-app" })
}

resource "aws_security_group" "backend" {
  name        = "${var.name_prefix}backend-sg"
  description = "Backend EC2 — accepts API traffic from internal ALB and SSH from Bastion."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb.id]
    description     = "API from internal ALB"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  lifecycle { create_before_destroy = true }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}backend-sg", Tier = "private-app" })
}

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}bastion-sg"
  description = "Bastion Host — SSH restricted to operator CIDRs."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
    description = "SSH from operator IPs — restrict in production"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  lifecycle { create_before_destroy = true }
  tags = merge(var.common_tags, { Name = "${var.name_prefix}bastion-sg", Tier = "public" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}rds-sg"
  description = "RDS PostgreSQL — accepts connections from backend SG only."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "PostgreSQL from backend instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Outbound within VPC only"
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}rds-sg", Tier = "private-data" })
}

resource "aws_iam_role" "frontend" {
  name = "${var.name_prefix}frontend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-role" })
}

resource "aws_iam_role_policy_attachment" "frontend_ssm"        { role = aws_iam_role.frontend.name; policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_role_policy_attachment" "frontend_cloudwatch" { role = aws_iam_role.frontend.name; policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" }

resource "aws_iam_role_policy" "frontend_secrets" {
  name = "${var.name_prefix}frontend-secrets-policy"
  role = aws_iam_role.frontend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue","secretsmanager:DescribeSecret"], Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/${var.environment}/*" }]
  })
}

resource "aws_iam_instance_profile" "frontend" {
  name = "${var.name_prefix}frontend-profile"
  role = aws_iam_role.frontend.name
  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-profile" })
}

resource "aws_iam_role" "backend" {
  name = "${var.name_prefix}backend-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = merge(var.common_tags, { Name = "${var.name_prefix}backend-role" })
}

resource "aws_iam_role_policy_attachment" "backend_ssm"        { role = aws_iam_role.backend.name; policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
resource "aws_iam_role_policy_attachment" "backend_cloudwatch" { role = aws_iam_role.backend.name; policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" }

resource "aws_iam_role_policy" "backend_secrets" {
  name = "${var.name_prefix}backend-secrets-policy"
  role = aws_iam_role.backend.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue","secretsmanager:DescribeSecret"], Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}/${var.environment}/*" }]
  })
}

resource "aws_iam_instance_profile" "backend" {
  name = "${var.name_prefix}backend-profile"
  role = aws_iam_role.backend.name
  tags = merge(var.common_tags, { Name = "${var.name_prefix}backend-profile" })
}