data "aws_iam_policy_document" "codedeploy_assumerole" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codedeploy" {
  name = "${local.project_code}-ecs-pipeline-deploy"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assumerole.json
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}