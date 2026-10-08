terraform {
  backend "s3" {
    bucket         = "terraform-assign-5-bucket"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-assign-5"
  }
}
