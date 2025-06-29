# Network Outputs
output "vpc_id" {
  description = "VPC network ID"
  value       = module.networking.vpc_id
}

output "vpc_connector_id" {
  description = "VPC Connector ID"
  value       = module.networking.vpc_connector_id
}

# Database Outputs
output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.database.instance_name
}

output "database_private_ip" {
  description = "Database private IP address"
  value       = module.database.private_ip_address
  sensitive   = true
}

output "database_connection_name" {
  description = "Database connection name"
  value       = module.database.connection_name
}

# Redis Outputs
output "redis_host" {
  description = "Redis host address"
  value       = module.redis.host
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

# Storage Outputs
output "storage_bucket_name" {
  description = "Storage bucket name"
  value       = module.storage.bucket_name
}

output "storage_bucket_url" {
  description = "Storage bucket URL"
  value       = module.storage.bucket_url
}

# Cloud Run Outputs
output "server_service_url" {
  description = "Medusa server service URL"
  value       = module.cloudrun.server_service_url
}

output "worker_service_url" {
  description = "Medusa worker service URL"
  value       = module.cloudrun.worker_service_url
}

# Load Balancer Outputs
output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = module.loadbalancer.ip_address
}

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = module.loadbalancer.url
}

# IAM Outputs
output "server_service_account_email" {
  description = "Server service account email"
  value       = module.iam.server_service_account_email
}

output "worker_service_account_email" {
  description = "Worker service account email"
  value       = module.iam.worker_service_account_email
}

# Secrets
output "db_url_secret_id" {
  description = "Database URL secret ID"
  value       = module.database.db_url_secret_id
}

output "redis_url_secret_id" {
  description = "Redis URL secret ID"
  value       = module.redis.redis_url_secret_id
}