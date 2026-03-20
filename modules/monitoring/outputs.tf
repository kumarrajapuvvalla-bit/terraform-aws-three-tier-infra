output "sns_alarm_topic_arn"         { value = aws_sns_topic.alarms.arn;                description = "SNS alarm topic ARN." }
output "cloudwatch_dashboard_name"    { value = aws_cloudwatch_dashboard.main.dashboard_name; description = "Dashboard name." }
output "cloudwatch_dashboard_url"     { value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"; description = "Dashboard URL." }
output "frontend_app_log_group_name"  { value = aws_cloudwatch_log_group.frontend_app.name; description = "Frontend app log group." }
output "backend_app_log_group_name"   { value = aws_cloudwatch_log_group.backend_app.name;  description = "Backend app log group." }
output "rds_log_group_name"           { value = aws_cloudwatch_log_group.rds.name;          description = "RDS log group." }