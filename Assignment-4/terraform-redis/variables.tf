variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet AZ-1"
  type        = string
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet AZ-2"
  type        = string
}

variable "private_subnet_3_cidr" {
  description = "CIDR block for private subnet AZ-3"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "my_ip" {
  description = "Your public IP address for SSH"
  type        = string
}

variable "redis_password" {
  description = "Password used by Redis and Sentinel"
  type        = string
  sensitive   = true
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  type        = string
}