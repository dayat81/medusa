# Production environment variables
# Copy from dev/variables.tf with production-appropriate defaults

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "alternative_zone" {
  description = "Alternative GCP Zone for HA"
  type        = string
  default     = "us-central1-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-custom-4-16384"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "medusa"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "medusa"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "enable_db_ha" {
  description = "Enable database high availability"
  type        = bool
  default     = true
}

variable "db_backup_start_time" {
  description = "Database backup start time (HH:MM)"
  type        = string
  default     = "03:00"
}

variable "redis_tier" {
  description = "Redis instance tier"
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_memory_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 5
}

variable "enable_redis_ha" {
  description = "Enable Redis high availability"
  type        = bool
  default     = true
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "artifact_registry_url" {
  description = "Artifact Registry base URL"
  type        = string
}

variable "server_cpu" {
  description = "Server CPU allocation"
  type        = string
  default     = "4"
}

variable "server_memory" {
  description = "Server memory allocation"
  type        = string
  default     = "4Gi"
}

variable "server_min_instances" {
  description = "Minimum number of server instances"
  type        = number
  default     = 2
}

variable "server_max_instances" {
  description = "Maximum number of server instances"
  type        = number
  default     = 20
}

variable "worker_cpu" {
  description = "Worker CPU allocation"
  type        = string
  default     = "2"
}

variable "worker_memory" {
  description = "Worker memory allocation"
  type        = string
  default     = "2Gi"
}

variable "worker_min_instances" {
  description = "Minimum number of worker instances"
  type        = number
  default     = 1
}

variable "worker_max_instances" {
  description = "Maximum number of worker instances"
  type        = number
  default     = 10
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = []
}

variable "domains" {
  description = "List of domains for SSL certificate"
  type        = list(string)
  default     = []
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = true
}