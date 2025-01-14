provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

terraform {
  backend "remote" {
    organization = "aws2023ac"
    
    workspaces {
      name = "Github-Actions-3"
    }
  }
}