# Terraform variables for Medusa GCP Jakarta Deployment

# Required variables
project_id  = "medusa-dev-jkt"
db_password = "MedusaDB2025SecurePassword!"

# Optional variables
region              = "asia-southeast2"
zone                = "asia-southeast2-a"
environment         = "dev"
node_count          = 2
node_machine_type   = "e2-medium"
enable_preemptible  = true
postgres_tier       = "db-f1-micro"
postgres_disk_size  = 20
redis_memory_size_gb = 1
enable_monitoring   = true
enable_backup       = true
backup_retention_days = 7
storage_bucket_name = "medusa-uploads"

# CORS origins for development
cors_origins = [
  "http://localhost:3000",
  "http://localhost:7001",
  "http://localhost:8000",
  "http://localhost:9000"
]

# Additional labels for resource organization
labels = {
  team        = "medusa-dev"
  cost_center = "engineering"
  owner       = "ptsec"
}