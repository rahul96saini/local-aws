output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.redis_vpc.id
}

output "bastion_public_ip" {
  description = "Public IP of Bastion"
  value       = aws_instance.bastion.public_ip
}

output "redis_primary_private_ip" {
  description = "Private IP of Redis Primary"
  value       = aws_instance.redis_primary.private_ip
}

output "redis_replica_private_ip" {
  description = "Private IP of Redis Replica"
  value       = aws_instance.redis_replica.private_ip
}

output "sentinel_3_private_ip" {
  description = "Private IP of Sentinel 3"
  value       = aws_instance.sentinel_3.private_ip
}

output "redis_sentinel_port" {
  value = 26379
}

output "redis_port" {
  value = 6379
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}