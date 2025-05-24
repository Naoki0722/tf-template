#############
# Security Groups
#############

# ALB用のセキュリティグループ定義
module "alb_sg" {
  source      = "./security_group"
  name        = "${local.project_code}-lb-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

# ecsで使用するインスタンス向けセキュリティグループ
module "service_sg" {
  source      = "./security_group"
  name        = "${local.project_code}-ecs-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = [aws_vpc.awsVpc.cidr_block]
}
