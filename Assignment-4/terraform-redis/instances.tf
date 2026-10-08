# =========================================================
# BASTION HOST
# =========================================================

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  tags = {
    Name = "redis-bastion"
  }
}


# =========================================================
# REDIS PRIMARY + SENTINEL 1
# =========================================================

resource "aws_instance" "redis_primary" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_1.id

  vpc_security_group_ids = [
    aws_security_group.redis.id,
    aws_security_group.sentinel.id
  ]

  key_name = var.key_name

  user_data = <<-EOF
#!/bin/bash

apt-get update -y
apt-get install -y redis-server

# Configure Redis
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode .*/protected-mode yes/' /etc/redis/redis.conf

echo "requirepass ${var.redis_password}" >> /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server

# Get Primary private IP
PRIMARY_IP=$(hostname -I | awk '{print $1}')

# Configure Sentinel
cat > /etc/redis/sentinel.conf <<SENTINEL
port 26379
bind 0.0.0.0
protected-mode no

sentinel monitor mymaster $PRIMARY_IP 6379 2
sentinel auth-pass mymaster ${var.redis_password}

sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
SENTINEL

cat > /etc/systemd/system/redis-sentinel.service <<SERVICE
[Unit]
Description=Redis Sentinel
After=network.target

[Service]
ExecStart=/usr/bin/redis-server /etc/redis/sentinel.conf --sentinel
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable redis-sentinel
systemctl start redis-sentinel
EOF

  tags = {
    Name = "redis-primary"
    Role = "Redis Primary + Sentinel 1"
  }
}


# =========================================================
# REDIS REPLICA + SENTINEL 2
# =========================================================

resource "aws_instance" "redis_replica" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private_2.id

  vpc_security_group_ids = [
    aws_security_group.redis.id,
    aws_security_group.sentinel.id
  ]

  key_name = var.key_name

  depends_on = [aws_instance.redis_primary]

  user_data = <<-EOF
#!/bin/bash

apt-get update -y
apt-get install -y redis-server

# Configure Redis
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode .*/protected-mode yes/' /etc/redis/redis.conf

echo "requirepass ${var.redis_password}" >> /etc/redis/redis.conf
echo "masterauth ${var.redis_password}" >> /etc/redis/redis.conf
echo "replicaof ${aws_instance.redis_primary.private_ip} 6379" >> /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server

# Configure Sentinel
cat > /etc/redis/sentinel.conf <<SENTINEL
port 26379
bind 0.0.0.0
protected-mode no

sentinel monitor mymaster ${aws_instance.redis_primary.private_ip} 6379 2
sentinel auth-pass mymaster ${var.redis_password}

sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
SENTINEL

cat > /etc/systemd/system/redis-sentinel.service <<SERVICE
[Unit]
Description=Redis Sentinel
After=network.target

[Service]
ExecStart=/usr/bin/redis-server /etc/redis/sentinel.conf --sentinel
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable redis-sentinel
systemctl start redis-sentinel
EOF

  tags = {
    Name = "redis-replica"
    Role = "Redis Replica + Sentinel 2"
  }
}


# =========================================================
# SENTINEL 3
# =========================================================

resource "aws_instance" "sentinel_3" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_3.id
  vpc_security_group_ids = [aws_security_group.sentinel.id]
  key_name               = var.key_name

  depends_on = [aws_instance.redis_primary]

  user_data = <<-EOF
#!/bin/bash

apt-get update -y
apt-get install -y redis-server

cat > /etc/redis/sentinel.conf <<SENTINEL
port 26379
bind 0.0.0.0
protected-mode no

sentinel monitor mymaster ${aws_instance.redis_primary.private_ip} 6379 2
sentinel auth-pass mymaster ${var.redis_password}

sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
SENTINEL

cat > /etc/systemd/system/redis-sentinel.service <<SERVICE
[Unit]
Description=Redis Sentinel
After=network.target

[Service]
ExecStart=/usr/bin/redis-server /etc/redis/sentinel.conf --sentinel
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable redis-sentinel
systemctl start redis-sentinel
EOF

  tags = {
    Name = "redis-sentinel-3"
    Role = "Redis Sentinel 3"
  }
}