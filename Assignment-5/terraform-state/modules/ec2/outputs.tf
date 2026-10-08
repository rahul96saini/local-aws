output "instance_ids" {
  value = {
    for name, instance in aws_instance.main :
    name => instance.id
  }
}

output "public_ips" {
  value = {
    for name, instance in aws_instance.main :
    name => instance.public_ip
  }
}

output "private_ips" {
  value = {
    for name, instance in aws_instance.main :
    name => instance.private_ip
  }
}