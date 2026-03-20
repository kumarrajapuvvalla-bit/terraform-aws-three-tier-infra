output "alb_security_group_id"           { value = aws_security_group.alb.id;          description = "External ALB SG ID." }
output "internal_alb_security_group_id"  { value = aws_security_group.internal_alb.id; description = "Internal ALB SG ID." }
output "frontend_security_group_id"      { value = aws_security_group.frontend.id;     description = "Frontend EC2 SG ID." }
output "backend_security_group_id"       { value = aws_security_group.backend.id;      description = "Backend EC2 SG ID." }
output "bastion_security_group_id"       { value = aws_security_group.bastion.id;      description = "Bastion SG ID." }
output "rds_security_group_id"           { value = aws_security_group.rds.id;          description = "RDS SG ID." }
output "frontend_instance_profile_arn"   { value = aws_iam_instance_profile.frontend.arn; description = "Frontend instance profile ARN." }
output "backend_instance_profile_arn"    { value = aws_iam_instance_profile.backend.arn;  description = "Backend instance profile ARN." }
output "frontend_role_arn"               { value = aws_iam_role.frontend.arn; description = "Frontend IAM role ARN." }
output "backend_role_arn"                { value = aws_iam_role.backend.arn;  description = "Backend IAM role ARN." }