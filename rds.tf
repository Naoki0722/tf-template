#############
# RDS (Relational Database Service)
#############

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${local.project_code}-db-subnet-group"
  subnet_ids = [
    aws_subnet.rds_private_0.id,
    aws_subnet.rds_private_1.id
  ]

  tags = {
    Name = "${local.project_code}-db-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.rds_config.engine == "mysql" ? "mysql8.0" : "postgres15"
  name   = "${local.project_code}-db-parameter-group"

  tags = {
    Name = "${local.project_code}-db-parameter-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "${local.project_code}-database"
  engine         = var.rds_config.engine
  engine_version = var.rds_config.engine_version
  instance_class = var.rds_config.instance_class

  allocated_storage     = var.rds_config.allocated_storage
  max_allocated_storage = var.rds_config.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = var.rds_config.storage_encrypted

  db_name  = var.rds_config.database_name
  username = var.rds_config.username

  # パスワードはSecrets Managerで管理
  manage_master_user_password = true

  # ネットワーク設定
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # 可用性とバックアップ
  multi_az               = var.rds_config.multi_az
  backup_retention_period = var.rds_config.backup_retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # パラメータとオプション
  parameter_group_name = aws_db_parameter_group.main.name

  # パフォーマンス設定
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn

  # CloudWatchログエクスポート
  enabled_cloudwatch_logs_exports = var.rds_config.engine == "mysql" ? ["error", "general", "slow_query"] : ["postgresql"]

  # 削除設定
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.project_code}-database-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = false
  delete_automated_backups  = false

  # その他設定
  auto_minor_version_upgrade = true
  apply_immediately         = false

  tags = {
    Name = "${local.project_code}-database"
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password
    ]
  }
}

# RDS Enhanced Monitoring用のIAMロール
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.project_code}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.project_code}-rds-monitoring-role"
  }
}

# Enhanced Monitoring用のポリシーアタッチ
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Group for RDS
resource "aws_cloudwatch_log_group" "rds_mysql_error" {
  count             = var.rds_config.engine == "mysql" ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/error"
  retention_in_days = 14

  tags = {
    Name = "${local.project_code}-rds-mysql-error-logs"
  }
}

resource "aws_cloudwatch_log_group" "rds_mysql_general" {
  count             = var.rds_config.engine == "mysql" ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/general"
  retention_in_days = 14

  tags = {
    Name = "${local.project_code}-rds-mysql-general-logs"
  }
}

resource "aws_cloudwatch_log_group" "rds_mysql_slowquery" {
  count             = var.rds_config.engine == "mysql" ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/slowquery"
  retention_in_days = 14

  tags = {
    Name = "${local.project_code}-rds-mysql-slowquery-logs"
  }
}

resource "aws_cloudwatch_log_group" "rds_postgresql" {
  count             = var.rds_config.engine == "postgres" ? 1 : 0
  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/postgresql"
  retention_in_days = 14

  tags = {
    Name = "${local.project_code}-rds-postgresql-logs"
  }
}
