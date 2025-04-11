terraform {
    required_version = "~> 1.11.3"

    required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.93.0"
    }
  }

  # Configure the backend to store Terraform state in S3
  backend "s3" {
    bucket       = "terraform-state-asl-foundation"  # S3 bucket name
    key          = "foundation/terraform.tfstate"    # Path to the state file
    region       = "us-west-2"                       # AWS region
    encrypt      = true                              # Enable server-side encryption
    use_lockfile = true                              # Enable lockfile to prevent concurrent access
  }
}

# AWS provider configuration
provider "aws" {
  region = "us-west-2"
  alias  = "management"

  # Configure default tags for all resources
  default_tags {
    tags = {
      terraform_managed = true # Tag to indicate resources managed by Terraform
      account           = "foundation" # Account name
    }
  }
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
