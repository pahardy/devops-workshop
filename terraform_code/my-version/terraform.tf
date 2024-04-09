terraform {
  required_providers {
    aws = {
      version = ">= 5.40.0"
      source = "hashicorp/aws"
    }
  }
}


provider "aws" {
  region = "ca-central-1"
}