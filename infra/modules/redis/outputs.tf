output "endpoint" {
  description = "Endpoint primario de Redis."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "port" {
  description = "Puerto de Redis."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].port
}
