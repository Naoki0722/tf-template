# ALBの定義
resource "aws_lb" "awsLb" {
  name                       = "awsLb"
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
    module.http_sg.security_group_id,
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
}

# ターゲットグループ
resource "aws_lb_target_group" "awsTargetGroup" {
  name                 = "awsTargetGroup"
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
    target_group_arn = aws_lb_target_group.awsTargetGroup.arn
  }

  condition {
    /*
    path_pattern {
      values = ["/*"]
    }
    */
    
    #Cloud Front経由のアクセスの場合のみForwardする。cloudfront.tfでヘッダーを設定している
    http_header {
      http_header_name = "x-pre-shared-key"
      values           = ["${var.forwardKey}"]
    }

  }
}

output "alb_dns_name" {
  value = aws_lb.awsLb.dns_name
}
output "alb_id" {
  value = aws_lb.awsLb.id
}

output "forwardKey" {
  value = "${var.forwardKey}"
}