# This file defines variables for the dev environment
# The actual values should be set in terraform.tfvars

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast2"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-southeast2-a"
}

variable "alternative_zone" {
  description = "Alternative GCP Zone for HA"
  type        = string
  default     = "asia-southeast2-b"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
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
  default     = false
}

variable "db_backup_start_time" {
  description = "Database backup start time (HH:MM)"
  type        = string
  default     = "03:00"
}

variable "redis_tier" {
  description = "Redis instance tier"
  type        = string
  default     = "BASIC"
}

variable "redis_memory_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

variable "enable_redis_ha" {
  description = "Enable Redis high availability"
  type        = bool
  default     = false
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
  default     = "1"
}

variable "server_memory" {
  description = "Server memory allocation"
  type        = string
  default     = "1Gi"
}

variable "server_min_instances" {
  description = "Minimum number of server instances"
  type        = number
  default     = 0
}

variable "server_max_instances" {
  description = "Maximum number of server instances"
  type        = number
  default     = 5
}

variable "worker_cpu" {
  description = "Worker CPU allocation"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Worker memory allocation"
  type        = string
  default     = "1Gi"
}

variable "worker_min_instances" {
  description = "Minimum number of worker instances"
  type        = number
  default     = 0
}

variable "worker_max_instances" {
  description = "Maximum number of worker instances"
  type        = number
  default     = 3
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "domains" {
  description = "List of domains for SSL certificate"
  type        = list(string)
  default     = []
}

variable "enable_cdn" {
  description = "Enable Cloud CDN"
  type        = bool
  default     = false
}

variable "enable_public_storage_access" {
  description = "Enable public access to storage buckets"
  type        = bool
  default     = true
}

variable "skip_vpc_connector" {
  description = "Skip VPC connector creation"
  type        = bool
  default     = false
}

variable "use_private_networking" {
  description = "Use private networking or serverless"
  type        = bool
  default     = false
}