# provider "aws" {
#   region = "us-east-1"
# }


terraform {
  required_providers {
    godaddy-dns = {
      source = "veksh/godaddy-dns"
      version = "0.3.12"
    }
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10" # Or any version < 2.11
    }
  
  }
}

