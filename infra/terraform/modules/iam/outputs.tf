output "server_service_account_email" {
  description = "Server service account email"
  value       = google_service_account.medusa_server.email
}

output "server_service_account_id" {
  description = "Server service account ID"
  value       = google_service_account.medusa_server.id
}

output "worker_service_account_email" {
  description = "Worker service account email"
  value       = google_service_account.medusa_worker.email
}

output "worker_service_account_id" {
  description = "Worker service account ID"
  value       = google_service_account.medusa_worker.id
}

output "cloudbuild_service_account_email" {
  description = "Cloud Build service account email"
  value       = var.enable_cicd ? google_service_account.cloudbuild[0].email : null
}

output "cloudbuild_service_account_id" {
  description = "Cloud Build service account ID"
  value       = var.enable_cicd ? google_service_account.cloudbuild[0].id : null
}

output "custom_role_id" {
  description = "Custom IAM role ID"
  value       = google_project_iam_custom_role.medusa_role.id
}

output "custom_role_name" {
  description = "Custom IAM role name"
  value       = google_project_iam_custom_role.medusa_role.name
}