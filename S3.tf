# プライベートバケットの定義
resource "aws_s3_bucket" "private" {
  # バケット名は世界で1意にしなければならない
  bucket = "${local.project_code}-ecs-private-terraform"
}

# versioningの有効化
resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 暗号化の設定
resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
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
}

# ライフサイクル設定の定義
resource "aws_s3_bucket_lifecycle_configuration" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "log-expiration"
    status = "Enabled"
    expiration {
      days = 60
    }
  }
}

# バケットポリシーの定義
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

# CodePipelineのartifact用バケット定義
resource "aws_s3_bucket" "pipeline_artifact" {}

resource "aws_s3_bucket_acl" "pipeline_artifact" {
  depends_on = [aws_s3_bucket.pipeline_artifact]

  bucket = aws_s3_bucket.pipeline_artifact.id
  acl    = "private"
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
