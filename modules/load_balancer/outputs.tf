output "external_alb_dns_name"    { value = aws_lb.external.dns_name;           description = "External ALB DNS name." }
output "external_alb_zone_id"     { value = aws_lb.external.zone_id;            description = "External ALB hosted zone ID." }
output "external_alb_arn"         { value = aws_lb.external.arn;                description = "External ALB ARN." }
output "external_alb_arn_suffix"  { value = aws_lb.external.arn_suffix;         description = "External ALB ARN suffix for CloudWatch." }
output "internal_alb_dns_name"    { value = aws_lb.internal.dns_name;           description = "Internal ALB DNS name." }
output "internal_alb_arn"         { value = aws_lb.internal.arn;                description = "Internal ALB ARN." }
output "frontend_target_group_arn" { value = aws_lb_target_group.frontend.arn;  description = "Frontend target group ARN." }
output "backend_target_group_arn"  { value = aws_lb_target_group.backend.arn;   description = "Backend target group ARN." }
output "frontend_target_group_name" { value = aws_lb_target_group.frontend.name; description = "Frontend target group name." }
output "backend_target_group_name"  { value = aws_lb_target_group.backend.name;  description = "Backend target group name." }