# Development environment outputs
output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "server_url" {
  description = "Medusa server URL"
  value       = module.medusa.server_service_url
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = module.medusa.load_balancer_ip
}

output "database_connection_name" {
  description = "Database connection name"
  value       = module.medusa.database_connection_name
}

output "storage_bucket" {
  description = "Storage bucket name"
  value       = module.medusa.storage_bucket_name
}

output "next_steps" {
  description = "Next steps for deployment"
  value = <<-EOT
    Your Medusa development environment has been deployed!
    
    Next steps:
    1. Update DNS to point to: ${module.medusa.load_balancer_ip}
    2. Build and push Docker images to: ${var.artifact_registry_url}
    3. Run database migrations
    4. Access your application at: ${module.medusa.server_service_url}
    
    Useful commands:
    - View logs: gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=medusa-server-dev"
    - Connect to database: gcloud sql connect ${module.medusa.database_instance_name} --user=${var.db_user}
  EOT
}