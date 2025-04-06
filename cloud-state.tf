# Create an S3 bucket to store Terraform state files
resource "aws_s3_bucket" "terraform_state" {
  bucket   = "terraform-state-asl-foundation"
  provider = aws.management

  tags = {
    Name = "Terraform State Bucket"
  }
}

# Enable versioning for the S3 bucket to preserve state history
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket   = aws_s3_bucket.terraform_state.id
  provider = aws.management


  versioning_configuration {
    status = "Enabled"
  }
}

# Configure lifecycle rules for the S3 bucket to manage object versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket   = aws_s3_bucket.terraform_state.id
  provider = aws.management

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Applies to all objects in the bucket
    }

    # transition {
    #   days          = 30
    #   storage_class = "GLACIER_IR"
    # }

    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class   = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      newer_noncurrent_versions = 1
      noncurrent_days           = 90
    }
  }
}

# Configure server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket   = aws_s3_bucket.terraform_state.id
  provider = aws.management

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_public_access" {
  bucket   = aws_s3_bucket.terraform_state.id
  provider = aws.management

  block_public_acls       = true # Block public ACLs
  block_public_policy     = true # Block public policies
  ignore_public_acls      = true # Ignore public ACLs
  restrict_public_buckets = true # Restrict public buckets
}

# S3 bucket policy to allow access from the organization
resource "aws_s3_bucket_policy" "terraform_state_policy" {
    bucket   = aws_s3_bucket.terraform_state.id
    provider = aws.management

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid       = "AllowOrgAccess"
                Effect    = "Allow"
                Principal = "*"
                Action    = "s3:*"
                Resource  = [
                    "arn:aws:s3:::${aws_s3_bucket.terraform_state.id}",
                    "arn:aws:s3:::${aws_s3_bucket.terraform_state.id}/*"
                ]
                Condition = {
                    StringEquals = {
                        "aws:PrincipalOrgID" = "o-en6164sihz"
                    }
                }
            }
        ]
    })
}