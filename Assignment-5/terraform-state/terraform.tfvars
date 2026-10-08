region   = "ap-south-1"
vpc_cidr = "10.0.0.0/16"

subnets = {
  public_1 = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    name              = "public-subnet-1"
  }

  public_2 = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    name              = "public-subnet-2"
  }

  private_1 = {
    cidr_block        = "10.0.11.0/24"
    availability_zone = "ap-south-1a"
    name              = "private-subnet-1"
  }

  private_2 = {
    cidr_block        = "10.0.12.0/24"
    availability_zone = "ap-south-1b"
    name              = "private-subnet-2"
  }
}

ami_id        = "ami-006f82a1d5a27da54"
instance_type = "t3.micro"
key_name      = "my_guru"