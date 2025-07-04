# Outputs for Medusa GCP Jakarta Deployment

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "zone" {
  description = "The GCP zone"
  value       = var.zone
}

# Network outputs
output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.medusa_vpc.name
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.medusa_vpc.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.medusa_subnet.name
}

output "subnet_ip_range" {
  description = "IP range of the subnet"
  value       = google_compute_subnetwork.medusa_subnet.ip_cidr_range
}

# GKE outputs
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.medusa_cluster.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.medusa_cluster.endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.medusa_cluster.master_auth.0.cluster_ca_certificate
  sensitive   = true
}

output "gke_service_account_email" {
  description = "Email of the GKE service account"
  value       = google_service_account.gke_node_sa.email
}

# Database outputs
output "postgres_instance_name" {
  description = "Name of the PostgreSQL instance"
  value       = google_sql_database_instance.medusa_postgres.name
}

output "postgres_connection_name" {
  description = "Connection name of the PostgreSQL instance"
  value       = google_sql_database_instance.medusa_postgres.connection_name
}

output "postgres_private_ip" {
  description = "Private IP address of the PostgreSQL instance"
  value       = google_sql_database_instance.medusa_postgres.private_ip_address
  sensitive   = true
}

output "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  value       = google_sql_database.medusa_db.name
}

output "postgres_user_name" {
  description = "Name of the PostgreSQL user"
  value       = google_sql_user.medusa_user.name
}

# Redis outputs
output "redis_instance_name" {
  description = "Name of the Redis instance"
  value       = google_redis_instance.medusa_redis.name
}

output "redis_host" {
  description = "Host of the Redis instance"
  value       = google_redis_instance.medusa_redis.host
  sensitive   = true
}

output "redis_port" {
  description = "Port of the Redis instance"
  value       = google_redis_instance.medusa_redis.port
}

output "redis_current_location_id" {
  description = "Current location ID of the Redis instance"
  value       = google_redis_instance.medusa_redis.current_location_id
}

# Storage outputs
output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket"
  value       = google_storage_bucket.medusa_uploads.name
}

output "storage_bucket_url" {
  description = "URL of the Cloud Storage bucket"
  value       = google_storage_bucket.medusa_uploads.url
}

# Artifact Registry outputs
output "artifact_registry_repository" {
  description = "Name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.medusa_repo.name
}

output "artifact_registry_location" {
  description = "Location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.medusa_repo.location
}

output "docker_repository_url" {
  description = "Docker repository URL for pushing images"
  value       = "${google_artifact_registry_repository.medusa_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.medusa_repo.repository_id}"
}

# Load Balancer outputs
output "load_balancer_ip" {
  description = "Static IP address for the load balancer"
  value       = google_compute_global_address.medusa_lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Name of the load balancer IP"
  value       = google_compute_global_address.medusa_lb_ip.name
}

# Secret Manager outputs
output "secret_names" {
  description = "Names of the Secret Manager secrets"
  value = {
    for secret_key, secret in google_secret_manager_secret.medusa_secrets : secret_key => secret.name
  }
}

# Connection strings (for application configuration)
output "database_connection_string" {
  description = "Database connection string (without password)"
  value       = "postgresql://${google_sql_user.medusa_user.name}:PASSWORD@${google_sql_database_instance.medusa_postgres.private_ip_address}:5432/${google_sql_database.medusa_db.name}"
  sensitive   = true
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${google_redis_instance.medusa_redis.host}:${google_redis_instance.medusa_redis.port}"
  sensitive   = true
}

# Kubernetes configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.medusa_cluster.name} --zone ${local.zone} --project ${var.project_id}"
}

# Docker build and push commands
output "docker_build_commands" {
  description = "Commands to build and push Docker image"
  value = [
    "# Configure Docker to use gcloud as a credential helper",
    "gcloud auth configure-docker ${google_artifact_registry_repository.medusa_repo.location}-docker.pkg.dev",
    "",
    "# Build the Docker image",
    "docker build -f Dockerfile.server -t ${google_artifact_registry_repository.medusa_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.medusa_repo.repository_id}/medusa:latest .",
    "",
    "# Push the Docker image",
    "docker push ${google_artifact_registry_repository.medusa_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.medusa_repo.repository_id}/medusa:latest"
  ]
}

# Summary information
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    project_id                = var.project_id
    region                   = var.region
    zone                     = var.zone
    gke_cluster_name         = google_container_cluster.medusa_cluster.name
    postgres_instance        = google_sql_database_instance.medusa_postgres.name
    redis_instance          = google_redis_instance.medusa_redis.name
    storage_bucket          = google_storage_bucket.medusa_uploads.name
    artifact_registry       = google_artifact_registry_repository.medusa_repo.name
    load_balancer_ip        = google_compute_global_address.medusa_lb_ip.address
    environment             = var.environment
  }
}