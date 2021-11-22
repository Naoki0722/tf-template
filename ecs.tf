# ECSクラスタの定義
resource "aws_ecs_cluster" "ecsCluster" {
  name = "ecsCluster"
}

# タスク定義
resource "aws_ecs_task_definition" "ecsTask" {
  family                   = "ecsTask"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

# サービス定義
resource "aws_ecs_service" "ecsService" {
  name                              = "ecsService"
  cluster                           = aws_ecs_cluster.ecsCluster.arn
  task_definition                   = aws_ecs_task_definition.ecsTask.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "nginx"
    container_port   = 80
  }
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  // deployやautoscaleで動的に変化する値を差分だしたくないので無視する
  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      load_balancer,
    ]
  }
  propagate_tags = "TASK_DEFINITION"
}

# ecsで使用するnginxインスタンス向けセキュリティグループ
module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = [aws_vpc.awsVpc.cidr_block]
}

# cloud watch ロギング
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/terraform"
  retention_in_days = 180
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
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}