output "redis_primary_endpoint" {
  description = "Primary Redis endpoint"
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.this.port
}
