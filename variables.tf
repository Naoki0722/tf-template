variable "userNumber" {
  type        = string
  description = "ユーザーのナンバー、arn内にある数字"
}

variable "forwardKey" {
  type        = string
  description = "cloudFront経由かどうか確認するKey"
}

variable "acmArm" {
  type        = string
  default     = null
  description = "acmによって作成した証明書のARN"
}

variable "gitRep" {
  type        = string
  description = "対象プロジェクトが格納されているgithubのリポジトリ、Saatisfy/watanabe-test-terraform  の様な形式"
}

variable "gitRepBranch" {
  type        = string
  description = "gitRepで入力したgithubのリポジトリ内の、変更を検知したいブランチ名"
}

variable "environments" {
  type = list(
    object({ name : string, value : string })
  )
  description = "コンテナ向け環境変数"
}

variable "service_name" {
  type        = string
  description = "サービス名"
}

variable "project_code" {
  type        = string
  description = "プロジェクトコード"
}

variable "aws" {
  type = object({
    access_key_id     = string
    secret_access_key = string
    region            = string
    profile           = string
  })
  description = "aws profile情報"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPCのcidr"
}

locals {
  service_name = var.service_name
  project_code = var.project_code
  stage        = terraform.workspace
  prefix       = "${local.project_code}-${local.stage}"
  region       = var.aws.region
  vpc_cidr     = var.vpc_cidr

  ecr_name = "${local.project_code}-ecr"

  # AWS認証情報
  profile = var.aws.profile
  aws_token = {
    aws_access_key_id     = var.aws.access_key_id
    aws_secret_access_key = var.aws.secret_access_key
    aws_region            = var.aws.region
  }

  deployAction = "STOP_DEPLOYMENT"
}
