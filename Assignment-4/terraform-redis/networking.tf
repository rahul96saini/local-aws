# =========================================================
# UBUNTU AMI
# =========================================================

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "redis_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "redis-vpc"
  }
}


# =========================================================
# INTERNET GATEWAY
# =========================================================

resource "aws_internet_gateway" "redis_igw" {
  vpc_id = aws_vpc.redis_vpc.id

  tags = {
    Name = "redis-igw"
  }
}


# =========================================================
# PUBLIC SUBNET
# =========================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.redis_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "redis-public-subnet"
  }
}


# =========================================================
# PRIVATE SUBNET - AZ 1
# =========================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.redis_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = "ap-south-1a"

  tags = {
    Name = "redis-private-subnet-1"
  }
}


# =========================================================
# PRIVATE SUBNET - AZ 2
# =========================================================

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.redis_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = "ap-south-1b"

  tags = {
    Name = "redis-private-subnet-2"
  }
}


# =========================================================
# PRIVATE SUBNET - AZ 3
# =========================================================

resource "aws_subnet" "private_3" {
  vpc_id            = aws_vpc.redis_vpc.id
  cidr_block        = var.private_subnet_3_cidr
  availability_zone = "ap-south-1c"

  tags = {
    Name = "redis-private-subnet-3"
  }
}


# =========================================================
# PUBLIC ROUTE TABLE
# =========================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.redis_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redis_igw.id
  }

  tags = {
    Name = "redis-public-route-table"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


# =========================================================
# ELASTIC IP FOR NAT
# =========================================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "redis-nat-eip"
  }
}


# =========================================================
# NAT GATEWAY
# =========================================================

resource "aws_nat_gateway" "redis_nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.redis_igw]

  tags = {
    Name = "redis-nat-gateway"
  }
}


# =========================================================
# PRIVATE ROUTE TABLE
# =========================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.redis_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.redis_nat.id
  }

  tags = {
    Name = "redis-private-route-table"
  }
}


# =========================================================
# PRIVATE ROUTE TABLE ASSOCIATIONS
# =========================================================

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private.id
}