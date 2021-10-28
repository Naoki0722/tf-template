# ALB用のセキュリティグループ定義
module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.awsVpc.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}