# watanabe-test-terraform

## 動作には下記形式のtfファイルを作成する必要があります

### variables.tf  default内を書き換え
variable "userNumber" {
    type= string
    default= "xxxxxxxx"
    description = "ユーザーのナンバー、arn内にある数字"
}

variable "forwardKey" {
    type= string
    default= "xxxxx"
    description = "cloudFront経由かどうか確認するKey、任意の文字列で良い"   
}