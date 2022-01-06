resource "aws_secretsmanager_secret" "aws_token" {
  name = "${local.project_code}-aws_token"
}

resource "aws_secretsmanager_secret_version" "aws_token" {
  secret_id = aws_secretsmanager_secret.aws_token.id
  secret_string = jsonencode(local.aws_token)
}