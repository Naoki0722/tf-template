service_name = "サービス名(hogehoge-service)"
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
  access_key_id     = "id"
  secret_access_key = "secret"
  region            = "ap-northeast-1"
  profile           = "my profile"
}
vpc_cidr = "10.0.0.0/16"
