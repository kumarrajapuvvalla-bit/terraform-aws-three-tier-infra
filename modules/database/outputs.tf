output "db_endpoint"            { value = aws_db_instance.primary.endpoint;   description = "RDS primary endpoint."; sensitive = true }
output "db_address"             { value = aws_db_instance.primary.address;    description = "RDS primary hostname."; sensitive = true }
output "db_port"                { value = aws_db_instance.primary.port;       description = "RDS port." }
output "db_replica_endpoint"    { value = aws_db_instance.replica.endpoint;   description = "RDS replica endpoint."; sensitive = true }
output "db_instance_identifier" { value = aws_db_instance.primary.identifier; description = "RDS primary identifier." }
output "db_replica_identifier"  { value = aws_db_instance.replica.identifier; description = "RDS replica identifier." }
output "db_subnet_group_name"   { value = aws_db_subnet_group.main.name;      description = "DB subnet group name." }
output "db_instance_arn"        { value = aws_db_instance.primary.arn;        description = "RDS primary ARN." }