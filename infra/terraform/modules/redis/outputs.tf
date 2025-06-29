output "instance_id" {
  description = "Redis instance ID"
  value       = google_redis_instance.medusa_redis.id
}

output "host" {
  description = "Redis host address"
  value       = google_redis_instance.medusa_redis.host
  sensitive   = true
}

output "port" {
  description = "Redis port"
  value       = google_redis_instance.medusa_redis.port
}

output "current_location_id" {
  description = "Current Redis location ID"
  value       = google_redis_instance.medusa_redis.current_location_id
}

output "persistence_iam_identity" {
  description = "Cloud IAM identity used by import/export operations"
  value       = google_redis_instance.medusa_redis.persistence_iam_identity
}

output "server_ca_certs" {
  description = "List of server CA certificates for the instance"
  value       = google_redis_instance.medusa_redis.server_ca_certs
  sensitive   = true
}

output "redis_url_secret_id" {
  description = "Redis URL secret ID"
  value       = google_secret_manager_secret.redis_url.secret_id
}

output "redis_config_secret_id" {
  description = "Redis configuration secret ID"
  value       = google_secret_manager_secret.redis_config.secret_id
}