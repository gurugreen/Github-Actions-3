terraform {
  backend "remote" {
    organization = "aws2023ac"
    
    workspaces {
      name = "Github-Actions-3"
    }
  }
}
