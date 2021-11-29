# プライベートバケットの定義
resource "aws_s3_bucket" "private" {
  # バケット名は世界で1意にしなければならない
  bucket = "${local.project_code}-ecs-private-terraform"

  versioning {
    enabled = true
  }

  # 暗号化を有効
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# ブロックパブリックアクセス
resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ログバケットの定義
resource "aws_s3_bucket" "alb_log" {
  bucket = "${local.project_code}-alb-log-ecs-terraform"

  lifecycle_rule {
    enabled = true

    expiration {
      days = "60"
    }
  }
}

# バケットポリシーの定義
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# CodePipelineのartifact用バケット定義
resource "aws_s3_bucket" "pipeline_artifact" {
  acl = "private"
}


data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${var.userNumber}"]
    }
  }
}