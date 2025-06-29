# Provider configurations are handled in versions.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
    "redis.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  service = each.value
  
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Networking module
module "networking" {
  source = "./modules/networking"

  project_id         = var.project_id
  region             = var.region
  environment        = var.environment
  skip_vpc_connector = var.skip_vpc_connector
  
  depends_on = [google_project_service.required_apis]
}

# IAM module
module "iam" {
  source = "./modules/iam"

  project_id  = var.project_id
  environment = var.environment
}

# Database module
module "database" {
  source = "./modules/database"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  vpc_id              = module.networking.vpc_id
  private_vpc_connection = module.networking.private_vpc_connection
  
  db_tier              = var.db_tier
  db_name              = var.db_name
  db_user              = var.db_user
  db_password          = var.db_password
  enable_ha            = var.enable_db_ha
  backup_start_time    = var.db_backup_start_time
  use_private_network  = var.use_private_networking
  
  depends_on = [module.networking]
}

# Redis module
module "redis" {
  source = "./modules/redis"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  zone        = var.zone
  
  vpc_id              = module.networking.vpc_id
  redis_tier           = var.redis_tier
  redis_memory_gb      = var.redis_memory_gb
  enable_ha            = var.enable_redis_ha
  alternative_zone     = var.alternative_zone
  use_private_network  = var.use_private_networking
  
  depends_on = [module.networking]
}

# Storage module
module "storage" {
  source = "./modules/storage"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  allowed_origins       = var.allowed_origins
  enable_public_access  = var.enable_public_storage_access
}

# Cloud Run module
module "cloudrun" {
  source = "./modules/cloudrun"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  vpc_connector_id = var.use_private_networking ? module.networking.vpc_connector_id : null
  
  # Service accounts
  server_service_account = module.iam.server_service_account_email
  worker_service_account = module.iam.worker_service_account_email
  
  # Database and Redis connections
  db_connection_name  = module.database.connection_name
  db_url_secret_id    = module.database.db_url_secret_id
  redis_url_secret_id = module.redis.redis_url_secret_id
  
  # Storage configuration
  storage_bucket_name = module.storage.bucket_name
  
  # Application configuration
  image_tag              = var.image_tag
  artifact_registry_url  = var.artifact_registry_url
  server_cpu            = var.server_cpu
  server_memory         = var.server_memory
  server_min_instances  = var.server_min_instances
  server_max_instances  = var.server_max_instances
  worker_cpu            = var.worker_cpu
  worker_memory         = var.worker_memory
  worker_min_instances  = var.worker_min_instances
  worker_max_instances  = var.worker_max_instances
  
  allowed_origins = var.allowed_origins
  
  depends_on = [module.networking, module.database, module.redis, module.storage, module.iam]
}

# Load Balancer module
module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  
  cloud_run_service_name = module.cloudrun.server_service_name
  cloud_run_service_url  = module.cloudrun.server_service_url
  domains               = var.domains
  enable_cdn            = var.enable_cdn
  
  depends_on = [module.cloudrun]
}