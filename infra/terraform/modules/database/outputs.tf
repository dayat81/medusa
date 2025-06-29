output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.medusa_db.name
}

output "connection_name" {
  description = "Cloud SQL connection name"
  value       = google_sql_database_instance.medusa_db.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.medusa_db.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = google_sql_database.medusa.name
}

output "database_user" {
  description = "Database username"
  value       = google_sql_user.medusa_user.name
}

output "ssl_cert" {
  description = "SSL certificate for database connection"
  value       = google_sql_ssl_cert.client_cert.cert
  sensitive   = true
}

output "ssl_private_key" {
  description = "SSL private key for database connection"
  value       = google_sql_ssl_cert.client_cert.private_key
  sensitive   = true
}

output "ssl_server_ca_cert" {
  description = "SSL server CA certificate"
  value       = google_sql_ssl_cert.client_cert.server_ca_cert
  sensitive   = true
}

output "db_url_secret_id" {
  description = "Database URL secret ID"
  value       = google_secret_manager_secret.db_url.secret_id
}

output "db_password_secret_id" {
  description = "Database password secret ID"
  value       = google_secret_manager_secret.db_password.secret_id
}