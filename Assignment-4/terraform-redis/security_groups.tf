# =========================================================
# BASTION SECURITY GROUP
# =========================================================

resource "aws_security_group" "bastion" {
  name        = "bastion-sg"
  description = "Security group for Bastion host"
  vpc_id      = aws_vpc.redis_vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}


# =========================================================
# REDIS SECURITY GROUP
# =========================================================

resource "aws_security_group" "redis" {
  name        = "redis-sg"
  description = "Security group for Redis servers"
  vpc_id      = aws_vpc.redis_vpc.id

  # SSH only from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Redis traffic from VPC
  ingress {
    description = "Redis traffic"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Sentinel communication from VPC
  ingress {
    description = "Sentinel communication"
    from_port   = 26379
    to_port     = 26379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redis-sg"
  }
}


# =========================================================
# SENTINEL SECURITY GROUP
# =========================================================

resource "aws_security_group" "sentinel" {
  name        = "sentinel-sg"
  description = "Security group for Redis Sentinel"
  vpc_id      = aws_vpc.redis_vpc.id

  # Sentinel communication
  ingress {
    description = "Sentinel communication"
    from_port   = 26379
    to_port     = 26379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Redis monitoring
  ingress {
    description = "Redis monitoring"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # SSH from Bastion
  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sentinel-sg"
  }
}