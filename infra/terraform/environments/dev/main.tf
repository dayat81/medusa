terraform {
  required_version = ">= 1.5.0"
  
  # Configure backend for state storage
  backend "gcs" {
    bucket = "medusa-terraform-state-dev-indonesia"
    prefix = "medusa/dev"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Include the main module
module "medusa" {
  source = "../../"

  # Pass all variables to the main module
  project_id        = var.project_id
  region           = var.region
  zone             = var.zone
  alternative_zone = var.alternative_zone
  environment      = var.environment

  # Database
  db_tier           = var.db_tier
  db_name           = var.db_name
  db_user           = var.db_user
  db_password       = var.db_password
  enable_db_ha      = var.enable_db_ha
  db_backup_start_time = var.db_backup_start_time

  # Redis
  redis_tier       = var.redis_tier
  redis_memory_gb  = var.redis_memory_gb
  enable_redis_ha  = var.enable_redis_ha

  # Application
  image_tag             = var.image_tag
  artifact_registry_url = var.artifact_registry_url

  # Server
  server_cpu           = var.server_cpu
  server_memory        = var.server_memory
  server_min_instances = var.server_min_instances
  server_max_instances = var.server_max_instances

  # Worker
  worker_cpu           = var.worker_cpu
  worker_memory        = var.worker_memory
  worker_min_instances = var.worker_min_instances
  worker_max_instances = var.worker_max_instances

  # Network
  allowed_origins = var.allowed_origins
  domains         = var.domains
  enable_cdn      = var.enable_cdn
  
  # Serverless Configuration
  use_private_networking       = var.use_private_networking
  enable_public_storage_access = var.enable_public_storage_access
  skip_vpc_connector          = var.skip_vpc_connector
}