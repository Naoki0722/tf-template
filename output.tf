output "alb_dns_name" {
  value = aws_lb.awsLb.dns_name
}
output "alb_id" {
  value = aws_lb.awsLb.id
}

output "forwardKey" {
  value = var.forwardKey
}

# RDS関連の出力
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_username" {
  description = "RDS master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "rds_master_user_secret_arn" {
  description = "ARN of the master user secret in Secrets Manager"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
