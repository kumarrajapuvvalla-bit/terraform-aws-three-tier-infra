output "frontend_asg_name"            { value = aws_autoscaling_group.frontend.name;          description = "Frontend ASG name." }
output "backend_asg_name"             { value = aws_autoscaling_group.backend.name;           description = "Backend ASG name." }
output "frontend_asg_arn"             { value = aws_autoscaling_group.frontend.arn;           description = "Frontend ASG ARN." }
output "backend_asg_arn"              { value = aws_autoscaling_group.backend.arn;            description = "Backend ASG ARN." }
output "bastion_instance_id"          { value = aws_instance.bastion.id;                      description = "Bastion instance ID." }
output "bastion_public_ip"            { value = aws_instance.bastion.public_ip;               description = "Bastion public IP." }
output "frontend_launch_template_id"  { value = aws_launch_template.frontend.id;              description = "Frontend Launch Template ID." }
output "backend_launch_template_id"   { value = aws_launch_template.backend.id;               description = "Backend Launch Template ID." }
output "frontend_scale_out_policy_arn" { value = aws_autoscaling_policy.frontend_scale_out.arn; description = "Frontend scale-out policy ARN." }
output "frontend_scale_in_policy_arn"  { value = aws_autoscaling_policy.frontend_scale_in.arn;  description = "Frontend scale-in policy ARN." }
output "backend_scale_out_policy_arn"  { value = aws_autoscaling_policy.backend_scale_out.arn;  description = "Backend scale-out policy ARN." }
output "backend_scale_in_policy_arn"   { value = aws_autoscaling_policy.backend_scale_in.arn;   description = "Backend scale-in policy ARN." }