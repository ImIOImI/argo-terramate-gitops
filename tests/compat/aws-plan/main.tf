# Plans offline: mock credentials and every AWS API lookup skipped.
provider "aws" {
  region     = "us-east-1"
  access_key = "mock"
  secret_key = "mock"

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

data "aws_partition" "current" {}

resource "aws_s3_bucket" "compat" {
  bucket = "compat-${data.aws_partition.current.partition}-probe"

  tags = {
    Purpose = "toolchain-compat"
  }
}

output "bucket" {
  value = aws_s3_bucket.compat.bucket
}
