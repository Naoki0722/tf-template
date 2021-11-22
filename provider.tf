provider "aws" {
  region = "ap-northeast-2"
}

provider "aws" {
  region = "us-east-1"
  alias = "virginia"
}