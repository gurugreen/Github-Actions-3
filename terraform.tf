provider "aws" {
  region = var.aws_region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

terraform {
  backend "remote" {
    organization = "aws2023ac"
    
    workspaces {
      name = "Github-Actions-3"
    }
  }
}