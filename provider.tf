provider "aws" {
  region = "us-east-2"
}

provider "aws" {
  region = "us-east-1"
  alias = "virginia"
}