# Root Terragrunt Configuration
# This file defines shared settings for ALL environments and modules.
# Every child terragrunt.hcl inherits these settings automatically.

# Generate AWS provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF
}

# Remote state configuration using S3 backend
# Each environment gets its own state file via key
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "nodejs-demoapp-terragrunt-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terragrunt-locks"
  }
}

# Default inputs for ALL modules
# These are merged with environment-specific inputs
inputs = {
  project_name = "nodejs-demoapp"
}
