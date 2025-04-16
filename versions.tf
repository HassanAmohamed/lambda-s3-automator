terraform {
  required_version = ">= 1.6.6, < 2.0.0"  # Allows newer 1.x versions

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.32.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# remote backend
terraform {
  backend "s3" {
    bucket         = "my-backend-devops103-terraform"
    key            = "lambda-function/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}