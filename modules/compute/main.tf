data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name";                values = ["al2023-ami-2023.*-x86_64"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
  filter { name = "root-device-type";    values = ["ebs"] }
}

resource "aws_launch_template" "frontend" {
  name_prefix            = "${var.name_prefix}frontend-lt-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.frontend_instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [var.frontend_sg_id]

  iam_instance_profile { arn = var.frontend_instance_profile_arn }

  user_data = base64encode(templatefile("${path.module}/../../templates/frontend_userdata.sh.tpl", {
    environment = var.environment
    project     = var.project_name
    aws_region  = var.aws_region
  }))

  monitoring { enabled = true }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs { volume_size = 20; volume_type = "gp3"; encrypted = true; delete_on_termination = true }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend", Tier = "presentation" })
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image_id]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}frontend-lt" })
}

resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.name_prefix}frontend-asg"
  vpc_zone_identifier       = var.private_app_subnet_ids
  min_size                  = var.frontend_min_size
  max_size                  = var.frontend_max_size
  desired_capacity          = var.frontend_desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [var.frontend_target_group_arn]

  launch_template { id = aws_launch_template.frontend.id; version = "$Latest" }

  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50; instance_warmup = 120 }
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, { Name = "${var.name_prefix}frontend", Tier = "presentation" })
    content { key = tag.key; value = tag.value; propagate_at_launch = true }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_launch_template" "backend" {
  name_prefix            = "${var.name_prefix}backend-lt-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = var.backend_instance_type
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile { arn = var.backend_instance_profile_arn }

  user_data = base64encode(templatefile("${path.module}/../../templates/backend_userdata.sh.tpl", {
    environment   = var.environment
    project       = var.project_name
    aws_region    = var.aws_region
    db_secret_arn = var.db_secret_arn
    db_endpoint   = var.db_endpoint
  }))

  monitoring { enabled = true }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs { volume_size = 20; volume_type = "gp3"; encrypted = true; delete_on_termination = true }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, { Name = "${var.name_prefix}backend", Tier = "application" })
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image_id]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}backend-lt" })
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.name_prefix}backend-asg"
  vpc_zone_identifier       = var.private_app_subnet_ids
  min_size                  = var.backend_min_size
  max_size                  = var.backend_max_size
  desired_capacity          = var.backend_desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [var.backend_target_group_arn]

  launch_template { id = aws_launch_template.backend.id; version = "$Latest" }

  instance_refresh {
    strategy = "Rolling"
    preferences { min_healthy_percentage = 50; instance_warmup = 120 }
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, { Name = "${var.name_prefix}backend", Tier = "application" })
    content { key = tag.key; value = tag.value; propagate_at_launch = true }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_ids[1]
  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name != "" ? var.key_pair_name : null

  user_data = base64encode(templatefile("${path.module}/../../templates/bastion_userdata.sh.tpl", {
    environment = var.environment
    aws_region  = var.aws_region
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 10
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags = merge(var.common_tags, { Name = "${var.name_prefix}bastion-vol" })
  }

  lifecycle { ignore_changes = [ami] }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}bastion", Tier = "public", Role = "bastion" })
}

resource "aws_autoscaling_policy" "frontend_scale_out" {
  name                   = "${var.name_prefix}frontend-scale-out"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "frontend_scale_in" {
  name                   = "${var.name_prefix}frontend-scale-in"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "backend_scale_out" {
  name                   = "${var.name_prefix}backend-scale-out"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "backend_scale_in" {
  name                   = "${var.name_prefix}backend-scale-in"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}