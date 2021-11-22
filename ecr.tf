resource "aws_ecr_repository" "main" {
  name                 = "dandle/server"
  image_tag_mutability = "MUTABLE"
}