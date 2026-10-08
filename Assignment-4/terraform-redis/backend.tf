# S3 backend will be enabled after the S3 bucket is created.

terraform {
  backend "s3" {
    bucket = "terraform-redis-rahul-statefile-bucket"
    key    = "redis/terraform.tfstate"
    region = "ap-south-1"
  }
}