output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application-tier subnet IDs."
  value       = module.networking.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "Private data-tier subnet IDs."
  value       = module.networking.private_data_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Elastic IPs assigned to NAT Gateways."
  value       = module.networking.nat_gateway_public_ips
}

output "external_alb_dns_name" {
  description = "DNS name of the internet-facing ALB. Point your domain here."
  value       = module.load_balancer.external_alb_dns_name
}

output "external_alb_zone_id" {
  description = "Hosted zone ID of the external ALB for Route 53 alias records."
  value       = module.load_balancer.external_alb_zone_id
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal ALB."
  value       = module.load_balancer.internal_alb_dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the Bastion Host."
  value       = module.compute.bastion_public_ip
}

output "frontend_asg_name" {
  description = "Name of the frontend Auto Scaling Group."
  value       = module.compute.frontend_asg_name
}

output "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group."
  value       = module.compute.backend_asg_name
}

output "db_endpoint" {
  description = "RDS primary endpoint — sensitive, never log this value."
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_replica_endpoint" {
  description = "RDS read replica endpoint."
  value       = module.database.db_replica_endpoint
  sensitive   = true
}

output "db_instance_identifier" {
  description = "RDS instance identifier."
  value       = module.database.db_instance_identifier
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for DB credentials."
  value       = module.secrets.db_secret_arn
  sensitive   = true
}

output "sns_alarm_topic_arn" {
  description = "ARN of the SNS alarm topic."
  value       = module.monitoring.sns_alarm_topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch operational dashboard."
  value       = module.monitoring.cloudwatch_dashboard_url
}