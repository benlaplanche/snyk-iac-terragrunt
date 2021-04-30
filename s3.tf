terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  # CHANGE ME to where your credentials are stored
  shared_credentials_file = "/Users/benlaplanche/.aws/credentials"
}

variable "s3_acl" {
  type    = string
  default = "public-read-write"
}

resource "aws_s3_bucket" "pictures-of-snyk-dogs" {
  bucket = "pictures-of-snyk-dogs"
  acl    = var.s3_acl

  tags = {
    Name        = "Pictures of Snyk Dogs"
    Environment = "Production"
  }
}
