resource "aws_instance" "main" {
  for_each = var.instances

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = each.value.subnet_id

  vpc_security_group_ids = [var.security_group_id]

  key_name = var.key_name

  tags = {
    Name = each.value.name
  }
}