terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.90.1"
    }

    awscc = {
      source  = "hashicorp/awscc"
      version = ">= 1.27.0"
    }

  }
}

provider "aws" {
  region = "us-east-1"
}

provider "awscc" {
  region = "us-east-1"
}
