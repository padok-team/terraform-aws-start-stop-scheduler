terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3"
    }
  }
}

provider "aws" {
  profile = "padok-lab"
  region  = "eu-west-3"
}
