# Terraformテンプレート

## 概要

このリポジトリは、AWSでECS Fargateサービスを構築し、CI/CDパイプラインを通じてアプリケーションをデプロイするためのTerraformテンプレートです。AWSのベストプラクティスに基づき、複数の環境（開発・ステージング・本番）で使用できるよう設計されています。

## アーキテクチャ

このTerraformテンプレートは以下のAWSリソースをプロビジョニングします：

- **ネットワーク**: VPC、パブリック/プライベートサブネット、インターネットゲートウェイ、NATゲートウェイ
- **コンテナ**: ECSクラスター、ECSサービス（Fargate）、ECRリポジトリ
- **データベース**: RDS（MySQL/PostgreSQL）、DB Subnet Group、セキュリティグループ
- **CI/CD**: CodePipeline、CodeBuild、CodeDeploy（ブルー/グリーンデプロイ）
- **ロードバランシング**: Application Load Balancer (ALB)、CloudFront
- **セキュリティ**: WAFv2、セキュリティグループ、IAMロール、Secrets Manager
- **ストレージ**: S3バケット（ログ、アーティファクト用）
- **ログ**: CloudWatch Logs

## 前提条件

- Terraform v1.0.0以上
- AWS CLIがインストール済みで設定済みのプロファイル
- GitHubリポジトリ（CI/CDパイプラインのソースとして使用）
- (オプション) ACMで発行済みの証明書ARN（CloudFrontでカスタムドメインを使用する場合）

## 使用方法

### 1-1. 変数の設定

`example.tfvars`をコピーして`terraform.tfvars`を作成し、必要な値を設定します：

```sh
cp example.tfvars terraform.tfvars
```

主な設定項目：
- AWS認証情報（アクセスキー、シークレットキー、リージョン）
- サービス名とプロジェクトコード
- GitHubリポジトリ情報（リポジトリ名、ブランチ名）
- 環境変数
- RDS設定（エンジン、インスタンスクラス、ストレージ、データベース名など）
- ACM証明書ARN（オプション）

### 1-2. 認証情報設定

基本的にはAWSのProfileを使って設定する

```sh
# 新しいプロファイルを設定
aws configure --profile your-profile-name

# 設定内容の確認
aws configure list --profile your-profile-name
```

applyする前には以下環境変数指定が必要


```sh
# プロファイルを環境変数で指定
export AWS_PROFILE=your-profile-name
```

### 2. Terraformの初期化と適用

```sh
# 初期化
terraform init

# ワークスペースの作成（環境ごと）
terraform workspace new dev  # または stg, prod

# プランの確認
terraform plan -var-file="terraform.tfvars"

# 適用
terraform apply -var-file="terraform.tfvars"
```

### 3. CodeStar Connection の承認

CodePipelineがGitHubリポジトリにアクセスするために、AWSコンソールでCodeStar Connectionを承認する必要があります：

1. AWSコンソールにログイン
2. Developer Tools > Settings > Connections に移動
3. 作成されたConnectionを選択し、「保留中の接続」をクリック
4. GitHubアカウントへの接続を承認

## CI/CDパイプライン

GitHubリポジトリの指定ブランチへのプッシュがトリガーとなり、次のフローが自動実行されます：

1. **ソース**: GitHubからコードを取得
2. **ビルド**: buildspec.yamlに基づきDockerイメージをビルドしECRにプッシュ
3. **デプロイ**: appspec.yamlに基づきECSサービスへブルー/グリーンデプロイ

## ファイル構成

- `alb.tf`: ALB関連のリソース定義
- `cloudfront.tf`: CloudFrontディストリビューション設定
- `codebuild.tf, codedeploy.tf, codepipeline.tf`: CI/CDパイプライン設定
- `ecr.tf`: ECRリポジトリの定義
- `ecs.tf`: ECSタスク実行ロールと関連セキュリティグループ
- `monitoring.tf`: CloudWatchアラームとログ設定
- `network.tf`: VPC、サブネット、ルートテーブル等
- `outputs.tf`: 出力変数の定義
- `provider.tf`: Terraformプロバイダー設定
- `rds.tf`: RDSインスタンス、DB Subnet Group、関連IAMロール設定
- `S3.tf`: S3バケット定義
- `security_groups.tf`: セキュリティグループ設定（ALB、ECS、RDS用）
- `variables.tf`: 入力変数の定義
- `waf.tf`: WAFv2 Web ACL設定
- `container_definitions/`: ECSタスク定義テンプレート
- `template/`: CodeBuild/CodeDeploy用テンプレート
- `iam_role/`: IAMロール定義
- `policy/`: IAMポリシー定義
- `security_group/`: セキュリティグループ定義

## 注意事項

- `terraform.tfvars`は機密情報を含むため、Gitリポジトリにコミットしないでください
- WAFはCloudFrontスコープで作成されるため、us-east-1リージョンのプロバイダーを使用しています
- 初回デプロイ後にCodeStar Connectionの手動承認が必要です
- RDSのマスターパスワードはSecrets Managerで自動管理されます
- 本番環境では、RDSの `deletion_protection` を `true` に設定することを推奨します
- RDSインスタンスの削除時には自動的にスナップショットが作成されます

## RDSについて

### データベース接続情報の取得

RDSインスタンスの接続情報は、以下のTerraform outputで取得できます：

```sh
# エンドポイント
terraform output rds_endpoint

# ポート番号
terraform output rds_port

# データベース名
terraform output rds_database_name

# マスターパスワードのSecrets Manager ARN
terraform output rds_master_user_secret_arn
```

### ECSタスクからのデータベースアクセス

ECSタスクはSecrets Managerからパスワードを自動取得してRDSに接続できます。アプリケーション側では以下の環境変数が利用可能です：

- `DB_HOST`: RDSエンドポイント
- `DB_PORT`: ポート番号
- `DB_NAME`: データベース名
- `DB_USERNAME`: マスターユーザー名
- `DB_PASSWORD_SECRET_ARN`: パスワードのSecrets Manager ARN
