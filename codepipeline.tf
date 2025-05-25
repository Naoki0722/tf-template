#############
#Code pipeline
#############
data "aws_iam_policy_document" "codepipeline_assumerole" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${local.project_code}-ecs-pipeline-project"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assumerole.json
}

resource "aws_iam_policy" "codepipeline" {
  name        = "${local.project_code}-ecs-pipeline-codepipeline"
  description = "${local.project_code}-ecs-pipeline-codepipeline"
  policy = templatefile("./policy/codepipeline_policy.tpl", {
    artifacts = aws_s3_bucket.pipeline_artifact.id
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  role       = aws_iam_role.codepipeline.id
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${local.project_code}-github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "main" {
  name     = "${local.project_code}-ecs-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifact.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = 1
      output_artifacts = ["source"]
      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = var.gitRep
        BranchName           = var.gitRepBranch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }

  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 2
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      configuration = {
        ProjectName = aws_codebuild_project.main.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployApp"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["build"]
      version         = 1
      run_order       = 3

      configuration = {
        ApplicationName                = aws_codedeploy_app.main.name
        DeploymentGroupName            = aws_codedeploy_app.main.name
        TaskDefinitionTemplateArtifact = "build"
        TaskDefinitionTemplatePath     = "service.json"
        AppSpecTemplateArtifact        = "build"
        AppSpecTemplatePath            = "appspec.yaml"
        Image1ArtifactName             = "build"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}
