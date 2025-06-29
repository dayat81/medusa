output "server_service_name" {
  description = "Server service name"
  value       = google_cloud_run_service.medusa_server.name
}

output "server_service_url" {
  description = "Server service URL"
  value       = google_cloud_run_service.medusa_server.status[0].url
}

output "worker_service_name" {
  description = "Worker service name"
  value       = google_cloud_run_service.medusa_worker.name
}

output "worker_service_url" {
  description = "Worker service URL"
  value       = google_cloud_run_service.medusa_worker.status[0].url
}

output "server_service_id" {
  description = "Server service ID"
  value       = google_cloud_run_service.medusa_server.id
}

output "worker_service_id" {
  description = "Worker service ID"
  value       = google_cloud_run_service.medusa_worker.id
}

output "cookie_secret_id" {
  description = "Cookie secret ID"
  value       = google_secret_manager_secret.cookie_secret.secret_id
}

output "jwt_secret_id" {
  description = "JWT secret ID"
  value       = google_secret_manager_secret.jwt_secret.secret_id
}