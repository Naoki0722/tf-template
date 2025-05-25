# AmazonECSTaskExecutionRolePolicy の参照
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#「AmazonECSTaskExecutionRolePolicy」ロールを継承したポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }

  # Secrets Manager access for RDS password
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_db_instance.main.master_user_secret[0].secret_arn]
  }
}

# ECSタスク実行ロールの作成
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "${local.project_code}-ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

#############
#ECS
#############

# ECSクラスタの定義
resource "aws_ecs_cluster" "ecsCluster" {
  name = "${local.project_code}-ecsCluster"
}

# タスク定義
resource "aws_ecs_task_definition" "ecsTask" {
  family                   = "${local.project_code}-ecsTask"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      "name" : "${local.project_code}-api",
      "image" : "nginx:latest",
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${local.region}",
          "awslogs-stream-prefix" : "${local.project_code}-api",
          "awslogs-group" : "/ecs/service"
        }
      },
      environment : concat(var.environments, [
        {
          "name" : "DB_HOST",
          "value" : aws_db_instance.main.endpoint
        },
        {
          "name" : "DB_PORT",
          "value" : tostring(aws_db_instance.main.port)
        },
        {
          "name" : "DB_NAME",
          "value" : aws_db_instance.main.db_name
        },
        {
          "name" : "DB_USERNAME",
          "value" : aws_db_instance.main.username
        }
      ]),
      secrets : [
        {
          "name" : "DB_PASSWORD",
          "valueFrom" : aws_db_instance.main.master_user_secret[0].secret_arn
        }
      ],
      "portMappings" : [
        {
          "protocol" : "tcp",
          "containerPort" : 80
        }
      ]
    }
  ])
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# サービス定義
resource "aws_ecs_service" "ecsService" {
  name                              = "${local.project_code}-ecsService"
  cluster                           = aws_ecs_cluster.ecsCluster.arn
  task_definition                   = aws_ecs_task_definition.ecsTask.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.service_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "${local.project_code}-api"
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
