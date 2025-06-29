# Production environment outputs
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

output "load_balancer_url" {
  description = "Load balancer URL"
  value       = module.medusa.load_balancer_url
}

output "database_connection_name" {
  description = "Database connection name"
  value       = module.medusa.database_connection_name
}

output "storage_bucket" {
  description = "Storage bucket name"
  value       = module.medusa.storage_bucket_name
}

output "domains" {
  description = "Configured domains"
  value       = var.domains
}

output "next_steps" {
  description = "Next steps for production deployment"
  value = <<-EOT
    Your Medusa production environment has been deployed!
    
    Load Balancer IP: ${module.medusa.load_balancer_ip}
    
    IMPORTANT PRODUCTION SETUP:
    1. DNS Configuration:
       - Point your domains to: ${module.medusa.load_balancer_ip}
       - Wait for SSL certificate provisioning (10-20 minutes)
    
    2. Image Deployment:
       - Build and push images to: ${var.artifact_registry_url}
       - Update image_tag variable and re-deploy
    
    3. Database Setup:
       - Run migrations: gcloud run jobs execute medusa-migrate --region=${var.region}
       - Create admin user
    
    4. Monitoring:
       - Set up alerting policies
       - Configure uptime checks
       - Review Cloud Logging and Monitoring
    
    5. Security:
       - Review IAM permissions
       - Enable audit logging
       - Configure backup verification
    
    Access URLs:
    ${length(var.domains) > 0 ? "- Main site: https://${var.domains[0]}" : "- IP-based access: http://${module.medusa.load_balancer_ip}"}
    ${length(var.domains) > 0 ? "- Admin: https://${var.domains[0]}/app" : "- Admin: http://${module.medusa.load_balancer_ip}/app"}
  EOT
}