resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "terraform-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "terraform-nat-gateway"
  }

  depends_on = [aws_eip.main]
}