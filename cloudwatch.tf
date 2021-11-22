resource "aws_cloudwatch_log_group" "codebuild" {
    name = "/codebuild/ecs-pipeline"
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "codebuild"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}