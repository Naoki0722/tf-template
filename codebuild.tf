data "aws_iam_policy_document" "codebuild_assumerole" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:*"
    ]
    resources = [
      aws_ecr_repository.main.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.pipeline_artifact.arn,
      "${aws_s3_bucket.pipeline_artifact.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }

  statement {
      effect = "Allow"
      actions = ["codestar-connections:UseConnection"]
      resources = [aws_codestarconnections_connection.github.arn]
    }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.project_code}-ecs-pipeline-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assumerole.json
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.project_code}-ecs-pipeline-codebuild"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild.json
}