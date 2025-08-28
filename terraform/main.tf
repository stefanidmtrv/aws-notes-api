
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "std-notes-app-terraform-state"
    key            = "global/s3/notes-app/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}
provider "aws" {
  region = "eu-north-1"
}


resource "aws_s3_bucket" "notes_api_terraform_state" {
  bucket = "std-notes-app-terraform-state"

  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.notes_api_terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.notes_api_terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}