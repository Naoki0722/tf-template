project_code = "任意のプロジェクトコード. 長過ぎるとエラーが出るため10文字程度"
userNumber   = "AWSのアカウントID"
forwardKey   = "任意のランダム文字列"
acmArm       = null
gitRep       = "Saatisfy/target_project"
gitRepBranch = "release/stg"
environments = [{
  name  = "hoge"
  value = "hage"
}]

aws = {
  region  = "ap-northeast-1"
  profile = "my profile"
}
vpc_cidr = "10.0.0.0/16"

# RDS設定
rds_config = {
  engine             = "mysql"        # または "postgres"
  engine_version     = "8.0"          # MySQLの場合は "8.0", PostgreSQLの場合は "15"
  instance_class     = "db.t3.micro"  # 本番では "db.t3.small" 以上を推奨
  allocated_storage  = 20             # 初期ストレージ容量（GB）
  database_name      = "appdb"        # データベース名
  username           = "admin"        # マスターユーザー名
  backup_retention   = 7              # バックアップ保持期間（日）
  multi_az           = true           # Multi-AZ配置（本番推奨）
  storage_encrypted  = true           # ストレージ暗号化
}
