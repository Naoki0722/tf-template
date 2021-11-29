data "aws_iam_policy_document" "codepipeline_assumerole" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
          type = "Service"
          identifiers = ["codepipeline.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "codepipeline" {
    name = "${local.project_code}-ecs-pipeline-project"
    assume_role_policy = data.aws_iam_policy_document.codepipeline_assumerole.json
}

resource "aws_iam_policy" "codepipeline" {
    name = "${local.project_code}-ecs-pipeline-codepipeline"
    description = "${local.project_code}-ecs-pipeline-codepipeline"
    policy = templatefile("./policy/codepipeline_policy.tpl", {
        artifacts = aws_s3_bucket.pipeline_artifact.id
    })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
    role = aws_iam_role.codepipeline.id
    policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}