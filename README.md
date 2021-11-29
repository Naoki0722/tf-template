# watanabe-test-terraform

## 動作にはルートディレクトリに下記tfファイルを作成する必要があります
exampleとしてvariables.tf.exampleを用意しておりますので、そちらをリネームして中身を入力していただいても構いません。
exampleの中身は下記と同様のものとなっております。

### variables.tf  
default内を書き換え

```
variable "userNumber" {
    type= string
    default= "xxxxxxxxxx"
    description = "ユーザーのナンバー、arn内にある数字"
}

variable "forwardKey" {
    type= string
    default= "xxxxxxxxxx"
    description = "cloudFront経由かどうか確認するKey"   
}

variable "acmArm" {
    type = string
    default = "xxxxxxxxxx"
    description = "acmによって作成した証明書のARN"
}

variable "gitRep" {
    type = string
    default = "xxxxxxxxxx"
    description = "対象プロジェクトが格納されているgithubのリポジトリ、Saatisfy/watanabe-test-terraform  の様な形式"
}

variable "gitRepBranch" {
    type = string
    default = "xxxxxxxxxx"
    description = "gitRepで入力したgithubのリポジトリ内の、変更を検知したいブランチ名"
}

locals {
    service_name = "testName"
    project_code = "tn"
    stage = "prod"
    prefix = "${local.project_code}-${stage}"
    region = "ap-northeast-2"
    vpc_cidr = "10.0.0.0/16"
    ecr_name = "${local.project_code}-ECR"
}

```

##環境ごとに変更が必要なファイル

###container_definitions.json
初回起動時のコンテナの名前や、コンテナポートの変更が必要。
変更点
- name
- containerPort

なお、imageはnginx:latestとなっているが、こちらはcode関係の設定後自動的に置き換わる

###appspec.yaml
container_definitions.jsonで指定したnameとcontainerPortと同じ内容で置き換える
変更点
- ContainerName
- ContainerPort

