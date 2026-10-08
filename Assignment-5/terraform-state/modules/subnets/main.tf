resource "aws_subnet" "main" {
  for_each = var.subnets

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.key == "public_1" || each.key == "public_2"

  tags = {
    Name = each.value.name
  }
}