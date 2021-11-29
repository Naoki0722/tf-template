# ALB用のセキュリティグループ定義
module "alb_sg" {
  source      = "./security_group"
  name        = "${local.project_code}-lb-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}
