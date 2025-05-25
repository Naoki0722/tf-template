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
    effect    = "Allow"
    actions   = ["codestar-connections:UseConnection"]
    resources = [aws_codestarconnections_connection.github.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
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

#############
#Code build
#############

resource "aws_codebuild_project" "main" {
  name          = "${local.project_code}-ecs-build"
  description   = "${local.project_code} ecs build"
  build_timeout = 60
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }
  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      status      = "ENABLED"
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = aws_cloudwatch_log_stream.codebuild.name
    }
    s3_logs {
      status = "DISABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yaml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    # AWS認証はCodeBuildのIAMロール (service_role) を使用
    # 環境変数での認証情報は不要

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = local.region
    }
  }
}
