# Terraformテンプレート

## 概要

このリポジトリは、AWSでECS Fargateサービスを構築し、CI/CDパイプラインを通じてアプリケーションをデプロイするためのTerraformテンプレートです。AWSのベストプラクティスに基づき、複数の環境（開発・ステージング・本番）で使用できるよう設計されています。

## アーキテクチャ

このTerraformテンプレートは以下のAWSリソースをプロビジョニングします：

- **ネットワーク**: VPC、パブリック/プライベートサブネット、インターネットゲートウェイ、NATゲートウェイ
- **コンテナ**: ECSクラスター、ECSサービス（Fargate）、ECRリポジトリ
- **CI/CD**: CodePipeline、CodeBuild、CodeDeploy（ブルー/グリーンデプロイ）
- **ロードバランシング**: Application Load Balancer (ALB)、CloudFront
- **セキュリティ**: WAFv2、セキュリティグループ、IAMロール
- **ストレージ**: S3バケット（ログ、アーティファクト用）
- **ログ**: CloudWatch Logs

## 前提条件

- Terraform v1.0.0以上
- AWS CLIがインストール済みで設定済みのプロファイル
- GitHubリポジトリ（CI/CDパイプラインのソースとして使用）
- (オプション) ACMで発行済みの証明書ARN（CloudFrontでカスタムドメインを使用する場合）

## 使用方法

### 1. 変数の設定

`example.tfvars`をコピーして`terraform.tfvars`を作成し、必要な値を設定します：

```sh
cp example.tfvars terraform.tfvars
```

主な設定項目：
- AWS認証情報（アクセスキー、シークレットキー、リージョン）
- サービス名とプロジェクトコード
- GitHubリポジトリ情報（リポジトリ名、ブランチ名）
- 環境変数
- ACM証明書ARN（オプション）

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
- `codebuild.tf, codedeploy.tf, codepipeline.tf`: CI/CDパイプラインの各コンポーネント設定
- `ecr.tf`: ECRリポジトリの定義
- `ecs.tf`: ECSタスク実行ロールと関連セキュリティグループ
- `network.tf`: VPC、サブネット、ルートテーブル等
- `provider.tf`: Terraformプロバイダー設定
- `S3.tf`: S3バケット定義
- `scm.tf`: Secrets Manager設定
- `service.tf`: メインのサービス定義（ECS、CloudFront等）
- `variables.tf`: 入力変数の定義
- `waf.tf`: WAFv2 Web ACL設定
- `container_definitions/`: ECSタスク定義テンプレート
- `template/`: CodeBuild/CodeDeploy用テンプレート

## 注意事項

- `terraform.tfvars`は機密情報を含むため、Gitリポジトリにコミットしないでください
- WAFはCloudFrontスコープで作成されるため、us-east-1リージョンのプロバイダーを使用しています
- 初回デプロイ後にCodeStar Connectionの手動承認が必要です

