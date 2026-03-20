resource "aws_lb" "external" {
  name               = "${var.name_prefix}ext-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(var.common_tags, { Name = "${var.name_prefix}ext-alb", Tier = "public" })
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.name_prefix}frontend-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-tg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.external.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}http-listener" })
}

resource "aws_lb_listener_rule" "frontend_forward" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition { path_pattern { values = ["/*"] } }
  action { type = "forward"; target_group_arn = aws_lb_target_group.frontend.arn }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-rule" })
}

resource "aws_lb" "internal" {
  name               = "${var.name_prefix}int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.private_app_subnet_ids

  tags = merge(var.common_tags, { Name = "${var.name_prefix}int-alb", Tier = "private-app" })
}

resource "aws_lb_target_group" "backend" {
  name        = "${var.name_prefix}backend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/api/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30
  tags = merge(var.common_tags, { Name = "${var.name_prefix}backend-tg" })

  lifecycle { create_before_destroy = true }
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 8080
  protocol          = "HTTP"

  default_action { type = "forward"; target_group_arn = aws_lb_target_group.backend.arn }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}internal-listener" })
}