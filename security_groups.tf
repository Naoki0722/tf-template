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

# RDS用のセキュリティグループ
resource "aws_security_group" "rds_sg" {
  name   = "${local.project_code}-rds-sg"
  vpc_id = aws_vpc.awsVpc.id

  tags = {
    Name = "${local.project_code}-rds-sg"
  }
}

# ECSからRDSへのアクセスを許可（MySQL/Aurora用）
resource "aws_security_group_rule" "rds_ingress_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.service_sg.security_group_id
  security_group_id        = aws_security_group.rds_sg.id
}

# ECSからRDSへのアクセスを許可（PostgreSQL用）
resource "aws_security_group_rule" "rds_ingress_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.service_sg.security_group_id
  security_group_id        = aws_security_group.rds_sg.id
}

# RDSからのアウトバウンドトラフィック
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_sg.id
}
