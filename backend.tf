terraform {
  backend "s3" {
    bucket = "chinwe-543808515815"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}