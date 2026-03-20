output "vpc_id"                    { value = aws_vpc.main.id; description = "VPC ID." }
output "vpc_cidr_block"             { value = aws_vpc.main.cidr_block; description = "VPC CIDR block." }
output "public_subnet_ids"          { value = aws_subnet.public[*].id; description = "Public subnet IDs." }
output "private_app_subnet_ids"     { value = aws_subnet.private_app[*].id; description = "Private app subnet IDs." }
output "private_data_subnet_ids"    { value = aws_subnet.private_data[*].id; description = "Private data subnet IDs." }
output "internet_gateway_id"        { value = aws_internet_gateway.main.id; description = "Internet Gateway ID." }
output "nat_gateway_ids"            { value = aws_nat_gateway.main[*].id; description = "NAT Gateway IDs." }
output "nat_gateway_public_ips"     { value = aws_eip.nat[*].public_ip; description = "NAT Gateway public EIPs." }
output "private_app_route_table_ids" { value = aws_route_table.private_app[*].id; description = "Private app route table IDs." }
output "vpc_flow_log_group_name"    { value = aws_cloudwatch_log_group.vpc_flow_logs.name; description = "VPC flow log group name." }