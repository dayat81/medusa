# Medusa E-commerce Platform - GCP Jakarta Deployment
# Terraform Configuration for Development Environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local values
locals {
  app_name    = "medusa"
  environment = "dev"
  region      = var.region
  zone        = var.zone
  
  labels = {
    app         = local.app_name
    environment = local.environment
    managed_by  = "terraform"
  }
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "redis.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "servicenetworking.googleapis.com"
  ])
  
  service = each.value
  project = var.project_id
  
  disable_dependent_services = false
  disable_on_destroy         = false
}

# VPC Network
resource "google_compute_network" "medusa_vpc" {
  name                    = "${local.app_name}-${local.environment}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  
  depends_on = [google_project_service.apis]
}

# Subnet for GKE cluster
resource "google_compute_subnetwork" "medusa_subnet" {
  name          = "${local.app_name}-${local.environment}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = local.region
  network       = google_compute_network.medusa_vpc.id
  
  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Cloud NAT for outbound internet access
resource "google_compute_router" "medusa_router" {
  name    = "${local.app_name}-${local.environment}-router"
  region  = local.region
  network = google_compute_network.medusa_vpc.id
}

resource "google_compute_router_nat" "medusa_nat" {
  name                               = "${local.app_name}-${local.environment}-nat"
  router                             = google_compute_router.medusa_router.name
  region                             = local.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rules
resource "google_compute_firewall" "medusa_firewall" {
  name    = "${local.app_name}-${local.environment}-firewall"
  network = google_compute_network.medusa_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "9000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["medusa-app"]
}

# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "medusa_repo" {
  location      = local.region
  repository_id = "${local.app_name}-${local.environment}"
  description   = "Docker repository for Medusa application"
  format        = "DOCKER"
  
  labels = local.labels
  
  depends_on = [google_project_service.apis]
}

# PostgreSQL Cloud SQL Instance
resource "google_sql_database_instance" "medusa_postgres" {
  name             = "${local.app_name}-${local.environment}-postgres"
  database_version = "POSTGRES_15"
  region           = local.region
  
  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = 20
    disk_autoresize   = true
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.medusa_vpc.id
      require_ssl     = true
    }
    
    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }
    
    user_labels = local.labels
  }
  
  deletion_protection = false
  
  depends_on = [
    google_project_service.apis,
    google_service_networking_connection.private_vpc_connection
  ]
}

# Database
resource "google_sql_database" "medusa_db" {
  name     = "medusa"
  instance = google_sql_database_instance.medusa_postgres.name
}

# Database user
resource "google_sql_user" "medusa_user" {
  name     = "medusa"
  instance = google_sql_database_instance.medusa_postgres.name
  password = var.db_password
}

# Private IP allocation for Cloud SQL
resource "google_compute_global_address" "private_ip_allocation" {
  name          = "${local.app_name}-${local.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.medusa_vpc.id
}

# VPC peering connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.medusa_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_allocation.name]
  
  depends_on = [google_project_service.apis]
}

# Redis instance for session management and caching
resource "google_redis_instance" "medusa_redis" {
  name           = "${local.app_name}-${local.environment}-redis"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = local.region
  
  location_id             = local.zone
  # alternative_location_id = "asia-southeast2-b"  # Not allowed for BASIC tier
  
  authorized_network = google_compute_network.medusa_vpc.id
  redis_version      = "REDIS_7_0"
  display_name       = "Medusa Redis Cache"
  
  labels = local.labels
  
  depends_on = [google_project_service.apis]
}

# GKE Cluster
resource "google_container_cluster" "medusa_cluster" {
  name     = "${local.app_name}-${local.environment}-cluster"
  location = local.zone
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = google_compute_network.medusa_vpc.name
  subnetwork = google_compute_subnetwork.medusa_subnet.name
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }
  
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "10.3.0.0/28"
  }
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }
  
  depends_on = [google_project_service.apis]
}

# GKE Node Pool
resource "google_container_node_pool" "medusa_nodes" {
  name       = "${local.app_name}-${local.environment}-nodes"
  location   = local.zone
  cluster    = google_container_cluster.medusa_cluster.name
  node_count = 2
  
  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    labels = local.labels
    tags   = ["medusa-app"]
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
  
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_node_sa" {
  account_id   = "${local.app_name}-${local.environment}-gke-sa"
  display_name = "GKE Node Service Account for Medusa"
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# Cloud Storage bucket for file uploads
resource "google_storage_bucket" "medusa_uploads" {
  name          = "${var.project_id}-${local.app_name}-${local.environment}-uploads"
  location      = local.region
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = local.labels
}

# IAM for Cloud Storage
resource "google_storage_bucket_iam_member" "medusa_bucket_access" {
  bucket = google_storage_bucket.medusa_uploads.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

# Secret Manager for sensitive configuration
resource "google_secret_manager_secret" "medusa_secrets" {
  for_each = toset([
    "jwt-secret",
    "cookie-secret",
    "database-url",
    "redis-url"
  ])
  
  secret_id = "${local.app_name}-${local.environment}-${each.value}"
  
  replication {
    auto {}
  }
  
  labels = local.labels
  
  depends_on = [google_project_service.apis]
}

# Store database URL in Secret Manager
resource "google_secret_manager_secret_version" "database_url" {
  secret      = google_secret_manager_secret.medusa_secrets["database-url"].id
  secret_data = "postgresql://${google_sql_user.medusa_user.name}:${var.db_password}@${google_sql_database_instance.medusa_postgres.private_ip_address}:5432/${google_sql_database.medusa_db.name}"
}

# Store Redis URL in Secret Manager
resource "google_secret_manager_secret_version" "redis_url" {
  secret      = google_secret_manager_secret.medusa_secrets["redis-url"].id
  secret_data = "redis://${google_redis_instance.medusa_redis.host}:${google_redis_instance.medusa_redis.port}"
}

# Load Balancer
resource "google_compute_global_address" "medusa_lb_ip" {
  name = "${local.app_name}-${local.environment}-lb-ip"
}