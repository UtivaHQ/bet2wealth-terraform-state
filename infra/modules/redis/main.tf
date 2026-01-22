# Redis Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  name       = "bet2wealth-backend-redis-subnet-group-${var.env}"
  subnet_ids = var.private_subnets

  tags = {
    Name        = "bet2wealth-backend-redis-subnet-group-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}

# Redis Security Group
resource "aws_security_group" "redis_sg" {
  name        = "bet2wealth-backend-redis-sg-${var.env}"
  description = "Allow Redis access from ECS only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bet2wealth-backend-redis-sg-${var.env}"
    Terraform   = "true"
    Environment = var.env
  }
}

# Redis Cluster
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "bet2wealth-redis-cluster-${var.env}"
  description          = "Redis for backend (${var.env})"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro" # Change to cache.t4g.micro for ARM architecture

  port = 6379

  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis_sg.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true

  num_cache_clusters = 2

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = {
    Environment = var.env
    Service     = "redis"
  }
}
