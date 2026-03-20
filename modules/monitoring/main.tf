resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}ops-alarms"
  tags = merge(var.common_tags, { Name = "${var.name_prefix}ops-alarms" })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

resource "aws_cloudwatch_log_group" "frontend_app" {
  name              = "/aws/ec2/${var.name_prefix}frontend/application"
  retention_in_days = var.cloudwatch_retention_days
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}frontend-app-logs" })
}

resource "aws_cloudwatch_log_group" "backend_app" {
  name              = "/aws/ec2/${var.name_prefix}backend/application"
  retention_in_days = var.cloudwatch_retention_days
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}backend-app-logs" })
}

resource "aws_cloudwatch_log_group" "bastion" {
  name              = "/aws/ec2/${var.name_prefix}bastion/system"
  retention_in_days = var.cloudwatch_retention_days
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}bastion-logs" })
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.name_prefix}postgres/postgresql"
  retention_in_days = var.cloudwatch_retention_days
  tags              = merge(var.common_tags, { Name = "${var.name_prefix}rds-logs" })
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_high" {
  alarm_name          = "${var.name_prefix}frontend-cpu-high"
  alarm_description   = "Frontend ASG CPU > ${var.cpu_alarm_threshold}% — scale out."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = { AutoScalingGroupName = var.frontend_asg_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}frontend-cpu-high" })
}

resource "aws_cloudwatch_metric_alarm" "frontend_cpu_low" {
  alarm_name          = "${var.name_prefix}frontend-cpu-low"
  alarm_description   = "Frontend ASG CPU < 30% — scale in."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  treat_missing_data  = "notBreaching"
  dimensions          = { AutoScalingGroupName = var.frontend_asg_name }
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}frontend-cpu-low" })
}

resource "aws_cloudwatch_metric_alarm" "backend_cpu_high" {
  alarm_name          = "${var.name_prefix}backend-cpu-high"
  alarm_description   = "Backend ASG CPU > ${var.cpu_alarm_threshold}% — scale out."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  treat_missing_data  = "notBreaching"
  dimensions          = { AutoScalingGroupName = var.backend_asg_name }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}backend-cpu-high" })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.name_prefix}alb-5xx-errors"
  alarm_description   = "External ALB 5xx errors elevated."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = var.external_alb_arn_suffix }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}alb-5xx" })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.name_prefix}rds-cpu-high"
  alarm_description   = "RDS CPU > 80%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  dimensions          = { DBInstanceIdentifier = var.db_instance_identifier }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}rds-cpu-high" })
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.name_prefix}rds-storage-low"
  alarm_description   = "RDS free storage below 5 GiB."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5368709120
  dimensions          = { DBInstanceIdentifier = var.db_instance_identifier }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  tags                = merge(var.common_tags, { Name = "${var.name_prefix}rds-storage-low" })
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"; x = 0; y = 0; width = 12; height = 6
        properties = {
          title   = "Frontend ASG — CPU"
          region  = var.aws_region
          metrics = [["AWS/EC2","CPUUtilization","AutoScalingGroupName",var.frontend_asg_name,{stat="Average",period=60}]]
          yAxis   = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric"; x = 12; y = 0; width = 12; height = 6
        properties = {
          title   = "Backend ASG — CPU"
          region  = var.aws_region
          metrics = [["AWS/EC2","CPUUtilization","AutoScalingGroupName",var.backend_asg_name,{stat="Average",period=60}]]
          yAxis   = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric"; x = 0; y = 6; width = 12; height = 6
        properties = {
          title   = "External ALB — Requests & 5xx"
          region  = var.aws_region
          metrics = [
            ["AWS/ApplicationELB","RequestCount","LoadBalancer",var.external_alb_arn_suffix,{stat="Sum",period=60}],
            ["AWS/ApplicationELB","HTTPCode_Target_5XX_Count","LoadBalancer",var.external_alb_arn_suffix,{stat="Sum",period=60,color="#d62728"}]
          ]
        }
      },
      {
        type = "metric"; x = 12; y = 6; width = 12; height = 6
        properties = {
          title   = "RDS Primary — CPU & Connections"
          region  = var.aws_region
          metrics = [
            ["AWS/RDS","CPUUtilization","DBInstanceIdentifier",var.db_instance_identifier,{stat="Average",period=60}],
            ["AWS/RDS","DatabaseConnections","DBInstanceIdentifier",var.db_instance_identifier,{stat="Average",period=60,yAxis="right"}]
          ]
        }
      }
    ]
  })
}