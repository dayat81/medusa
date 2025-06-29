output "bucket_name" {
  description = "Uploads bucket name"
  value       = google_storage_bucket.medusa_uploads.name
}

output "bucket_url" {
  description = "Uploads bucket URL"
  value       = google_storage_bucket.medusa_uploads.url
}

output "static_bucket_name" {
  description = "Static assets bucket name"
  value       = google_storage_bucket.medusa_static.name
}

output "static_bucket_url" {
  description = "Static assets bucket URL"
  value       = google_storage_bucket.medusa_static.url
}

output "backup_bucket_name" {
  description = "Backup bucket name"
  value       = var.environment == "prod" ? google_storage_bucket.medusa_backups[0].name : ""
}

output "backup_bucket_url" {
  description = "Backup bucket URL"
  value       = var.environment == "prod" ? google_storage_bucket.medusa_backups[0].url : ""
}

output "storage_config_secret_id" {
  description = "Storage configuration secret ID"
  value       = google_secret_manager_secret.storage_config.secret_id
}