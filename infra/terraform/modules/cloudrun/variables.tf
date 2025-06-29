variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC Connector ID (optional for serverless)"
  type        = string
  default     = null
}

variable "db_connection_name" {
  description = "Database connection name for Cloud SQL Proxy"
  type        = string
}

variable "server_service_account" {
  description = "Service account email for server"
  type        = string
}

variable "worker_service_account" {
  description = "Service account email for worker"
  type        = string
}

variable "db_url_secret_id" {
  description = "Database URL secret ID"
  type        = string
}

variable "redis_url_secret_id" {
  description = "Redis URL secret ID"
  type        = string
}

variable "storage_bucket_name" {
  description = "Storage bucket name"
  type        = string
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
  default     = "2"
}

variable "server_memory" {
  description = "Server memory allocation"
  type        = string
  default     = "2Gi"
}

variable "server_min_instances" {
  description = "Minimum number of server instances"
  type        = number
  default     = 1
}

variable "server_max_instances" {
  description = "Maximum number of server instances"
  type        = number
  default     = 10
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
  default     = 1
}

variable "worker_max_instances" {
  description = "Maximum number of worker instances"
  type        = number
  default     = 5
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}