resource "aws_ecr_repository" "main" {
  name = local.ecr_name
}
