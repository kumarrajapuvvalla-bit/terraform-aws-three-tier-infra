data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)
  db_password    = local.db_credentials["password"]
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.name_prefix}db-subnet-group"
  description = "RDS subnet group spanning both AZs."
  subnet_ids  = var.db_subnet_ids
  tags        = merge(var.common_tags, { Name = "${var.name_prefix}db-subnet-group" })
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.name_prefix}postgres-params"
  family      = "postgres15"
  description = "Custom parameter group for PostgreSQL 15."

  parameter { name = "log_min_duration_statement"; value = "1000" }
  parameter { name = "log_connections";            value = "1" }
  parameter { name = "log_disconnections";         value = "1" }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}postgres-params" })
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.name_prefix}rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "monitoring.rds.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = merge(var.common_tags, { Name = "${var.name_prefix}rds-monitoring-role" })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "primary" {
  identifier        = "${var.name_prefix}postgres-primary"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  db_name           = var.db_name
  username          = var.db_username
  password          = local.db_password

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.db_security_group_ids
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az                  = var.db_multi_az
  backup_retention_period   = var.db_backup_retention_period
  backup_window             = "02:00-03:00"
  maintenance_window        = "sun:05:00-sun:06:00"
  deletion_protection       = var.db_deletion_protection
  delete_automated_backups  = false

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  performance_insights_enabled    = true

  auto_minor_version_upgrade = true
  apply_immediately          = false

  skip_final_snapshot       = var.db_deletion_protection ? false : true
  final_snapshot_identifier = var.db_deletion_protection ? "${var.name_prefix}postgres-final-snap" : null

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [password]
  }

  tags = merge(var.common_tags, { Name = "${var.name_prefix}postgres-primary", Tier = "data", Role = "primary" })
}

resource "aws_db_instance" "replica" {
  identifier          = "${var.name_prefix}postgres-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = var.db_instance_class

  auto_minor_version_upgrade   = true
  vpc_security_group_ids       = var.db_security_group_ids
  publicly_accessible          = false
  backup_retention_period      = 0
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_enhanced_monitoring.arn
  skip_final_snapshot          = true

  tags = merge(var.common_tags, { Name = "${var.name_prefix}postgres-replica", Tier = "data", Role = "replica" })
}