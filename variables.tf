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
  description = "対象プロジェクトが格納されているgithubのリポジトリ、Username/repositoryName  の様な形式"
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

variable "project_code" {
  type        = string
  description = "プロジェクトコード"
}

variable "aws" {
  type = object({
    region  = string
    profile = string
  })
  description = "aws profile情報（profileを使用する場合、access_key_idとsecret_access_keyは不要）"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPCのcidr"
}

variable "rds_config" {
  type = object({
    engine             = string
    engine_version     = string
    instance_class     = string
    allocated_storage  = number
    database_name      = string
    username           = string
    backup_retention   = number
    multi_az           = bool
    storage_encrypted  = bool
  })
  default = {
    engine             = "mysql"
    engine_version     = "8.0"
    instance_class     = "db.t3.micro"
    allocated_storage  = 20
    database_name      = "appdb"
    username           = "admin"
    backup_retention   = 7
    multi_az           = true
    storage_encrypted  = true
  }
  description = "RDS設定"
}

locals {
  project_code = var.project_code
  stage        = terraform.workspace
  prefix       = "${local.project_code}-${local.stage}"
  region       = var.aws.region
  vpc_cidr     = var.vpc_cidr

  ecr_name = "${local.project_code}-ecr"

  # AWS認証情報
  profile = var.aws.profile

  deployAction = "STOP_DEPLOYMENT"
}
