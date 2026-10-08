module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = var.vpc_cidr
}

module "subnets" {
  source = "./modules/subnets"

  vpc_id  = module.vpc.vpc_id
  subnets = var.subnets
}

module "igw" {
  source = "./modules/igw"

  vpc_id = module.vpc.vpc_id
}

module "nat_gateway" {
  source = "./modules/nat-gateway"

  public_subnet_id = module.subnets.subnet_ids["public_1"]
}

module "route_table" {
  source = "./modules/route-table"

  vpc_id = module.vpc.vpc_id

  igw_id         = module.igw.igw_id
  nat_gateway_id = module.nat_gateway.nat_gateway_id

  public_subnet_ids = [
    module.subnets.subnet_ids["public_1"],
    module.subnets.subnet_ids["public_2"]
  ]

  private_subnet_ids = [
    module.subnets.subnet_ids["private_1"],
    module.subnets.subnet_ids["private_2"]
  ]
}

module "security_group" {
  source = "./modules/security-group"

  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source = "./modules/ec2"

  security_group_id = module.security_group.security_group_id

  ami_id        = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  instances = {
    public_1 = {
      subnet_id = module.subnets.subnet_ids["public_1"]
      name      = "public-ec2-1"
    }

    public_2 = {
      subnet_id = module.subnets.subnet_ids["public_2"]
      name      = "public-ec2-2"
    }

    private_1 = {
      subnet_id = module.subnets.subnet_ids["private_1"]
      name      = "private-ec2-1"
    }

    private_2 = {
      subnet_id = module.subnets.subnet_ids["private_2"]
      name      = "private-ec2-2"
    }
  }
}