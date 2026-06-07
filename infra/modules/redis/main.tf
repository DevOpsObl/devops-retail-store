# Grupo de subredes privadas donde ElastiCache puede crear Redis.
resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

# Cluster Redis administrado usado para estado temporal de checkout.
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [var.security_group_id]

  tags = var.tags
}
