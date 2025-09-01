# provider "aws" {
#   region = "us-east-1"
# }


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"  # Fixed: was pointing to hashicorp/aws
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"  # Fixed: removed the "Or any version < 2.11" comment
    }
  }
}

