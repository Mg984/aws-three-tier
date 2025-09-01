# provider "aws" {
#   region = "us-east-1"
# }


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source = "hashicorp/aws"
      version = "~> 2.20"  
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10" # Or any version < 2.11
    }
  
  }
}

