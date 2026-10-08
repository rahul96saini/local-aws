output "subnet_ids" {
  value = {
    for name, subnet in aws_subnet.main :
    name => subnet.id
  }
}