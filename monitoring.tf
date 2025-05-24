#############
#Cloud watch
#############

# cloud watch ロギング
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/service"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name = "/codebuild/${local.project_code}ecs-pipeline"
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "${local.project_code}-codebuild"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}
