#############
#ALB
#############

# ALBの定義
resource "aws_lb" "awsLb" {
  name                       = "${local.project_code}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = false
  }

  security_groups = [
    module.alb_sg.security_group_id,
  ]
}

# ALBリスナーの定義
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.awsLb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
  lifecycle {
    ignore_changes = [default_action]
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "blue" {
  name                 = "${local.project_code}-blue"
  vpc_id               = aws_vpc.awsVpc.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.awsLb]
}

resource "aws_lb_target_group" "green" {
  name                 = "${local.project_code}-green"
  vpc_id               = aws_vpc.awsVpc.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.awsLb]
}

# リスナールール
resource "aws_lb_listener_rule" "awsListenerRule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    #Cloud Front経由のアクセスの場合のみForwardする。cloudfront.tfでヘッダーを設定している
    http_header {
      http_header_name = "x-pre-shared-key"
      values           = ["${var.forwardKey}"]
    }

  }
}

#############
#Cloud Front
#############
resource "aws_cloudfront_distribution" "static-www" {
  //代替ドメイン
  //aliases = ["watanabe.dbgso.com"]
  web_acl_id = aws_wafv2_web_acl.default.arn
  origin {
    domain_name = aws_lb.awsLb.dns_name
    origin_id   = aws_lb.awsLb.dns_name
    custom_header {
      name  = "x-pre-shared-key"
      value = var.forwardKey
    }
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_lb.awsLb.dns_name

    forwarded_values {
      query_string = false
      headers      = ["Host"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    //証明書の設定
    # acm_certificate_arn = var.acmArm
    # ssl_support_method = "sni-only"
    # minimum_protocol_version = "TLSv1"
  }
}

resource "aws_cloudfront_origin_access_identity" "static-www" {}


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
      environment : var.environments,
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
  platform_version                  = "1.3.0"
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

# cloud watch ロギング
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/service"
  retention_in_days = 180
}

#############
#Cloud watch
#############

resource "aws_cloudwatch_log_group" "codebuild" {
  name = "/codebuild/${local.project_code}ecs-pipeline"
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "${local.project_code}-codebuild"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}


#############
#Code pipeline
#############

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
        ProjectName = "ecs-build"
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
        Image1ContainerName            = "${local.project_code}-api"
      }
    }
  }
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
    environment_variable {
      name  = "aws_access_key_id"
      type  = "SECRETS_MANAGER"
      value = "${local.project_code}-aws_token:aws_access_key_id"
    }

    environment_variable {
      name  = "aws_secret_access_key"
      type  = "SECRETS_MANAGER"
      value = "${local.project_code}-aws_token:aws_secret_access_key"
    }

    environment_variable {
      name  = "aws_region"
      type  = "SECRETS_MANAGER"
      value = "${local.project_code}-aws_token:aws_region"
    }

  }
}


#############
#Code deploy
#############

resource "aws_codedeploy_app" "main" {
  compute_platform = "ECS"
  name             = "${local.service_name}-api"
}

resource "aws_codedeploy_deployment_group" "main" {
  deployment_group_name  = "${local.service_name}-api"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  app_name               = aws_codedeploy_app.main.name
  service_role_arn       = aws_iam_role.codedeploy.arn

  auto_rollback_configuration {
    enabled = true
    events = [
      "DEPLOYMENT_FAILURE"
    ]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = local.deployAction
      wait_time_in_minutes = 30
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecsCluster.name
    service_name = aws_ecs_service.ecsService.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_lb_listener.http.arn
        ]
      }
      target_group {
        name = aws_lb_target_group.blue.name
      }
      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }
}
