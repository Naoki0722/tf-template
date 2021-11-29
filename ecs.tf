# ecsで使用するインスタンス向けセキュリティグループ
module "service_sg" {
  source      = "./security_group"
  name        = "${local.project_code}-ecs-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = [aws_vpc.awsVpc.cidr_block]
}

# AmazonECSTaskExecutionRolePolicy の参照
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#「AmazonECSTaskExecutionRolePolicy」ロールを継承したポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

# ECSタスク実行ロールの作成
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "${local.project_code}-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}