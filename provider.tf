
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.45.0"
    }
  }
  backend "s3" {
    bucket = "watanabe-terraform-state"
    key = "terraform/template/terraform.tfstate"
    region = "ap-northeast-2"
  }
}
provider "aws" {
  region = local.region
}

provider "aws" {
  region = "us-east-1"
  alias = "virginia"
}