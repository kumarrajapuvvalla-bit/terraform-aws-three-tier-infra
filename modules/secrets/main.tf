data "aws_caller_identity" "current" {}

resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  lifecycle { ignore_changes = all }
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project_name}/${var.environment}/db/credentials"
  description             = "RDS credentials for the ${var.environment} environment."
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(var.common_tags, { Name = "${var.name_prefix}db-credentials" })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
    engine   = "postgres"
    port     = 5432
  })

  lifecycle { ignore_changes = [secret_string] }
}