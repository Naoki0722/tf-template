# VPC定義
resource "aws_vpc" "awsVpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.project_code}-Vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "awsGateway" {
  vpc_id = aws_vpc.awsVpc.id
}

# パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.awsVpc.id
}

# パブリックルート
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.awsGateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# パブリックサブネット 1a
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = true
}

# パブリックサブネット 1c
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${local.region}c"
  map_public_ip_on_launch = true
}

# サブネットとルートテーブルの紐付け
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

# サブネットとルートテーブルの紐付け
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# EIP (NATゲートウェイ 1a)
resource "aws_eip" "nat_gateway_0" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.awsGateway]
}

# EIP (NATゲートウェイ 1c)
resource "aws_eip" "nat_gateway_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.awsGateway]
}

# NATゲートウェイ 1a
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.awsGateway]
}

# NATゲートウェイ 1c
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.awsGateway]
}

# プライベートルートテーブル 1a
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.awsVpc.id
}

# プライベートルートテーブル 1c
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.awsVpc.id
}

# プライベートルート 1a
resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

# プライベートルート 1c
resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

# プライベートサブネット 1a
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = false
}

# プライベートサブネット 1c
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "${local.region}c"
  map_public_ip_on_launch = false
}

# サブネットとルートテーブルの紐付け
resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

# サブネットとルートテーブルの紐付け
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# RDS専用プライベートサブネット 1a
resource "aws_subnet" "rds_private_0" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.67.0/24"
  availability_zone       = "${local.region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.project_code}-rds-private-subnet-1a"
  }
}

# RDS専用プライベートサブネット 1c
resource "aws_subnet" "rds_private_1" {
  vpc_id                  = aws_vpc.awsVpc.id
  cidr_block              = "10.0.68.0/24"
  availability_zone       = "${local.region}c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.project_code}-rds-private-subnet-1c"
  }
}

# RDSサブネットとルートテーブルの紐付け
resource "aws_route_table_association" "rds_private_0" {
  subnet_id      = aws_subnet.rds_private_0.id
  route_table_id = aws_route_table.private_0.id
}

# RDSサブネットとルートテーブルの紐付け
resource "aws_route_table_association" "rds_private_1" {
  subnet_id      = aws_subnet.rds_private_1.id
  route_table_id = aws_route_table.private_1.id
}
