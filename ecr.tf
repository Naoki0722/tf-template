resource "aws_ecr_repository" "main" {
  name                 = "${local.ecr_name}"
  image_tag_mutability = "MUTABLE"
}