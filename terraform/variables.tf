# Variables for Medusa GCP Jakarta Deployment

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "asia-southeast2"
  validation {
    condition     = can(regex("^asia-southeast2", var.region))
    error_message = "Region must be asia-southeast2 (Jakarta) or its zones."
  }
}

variable "zone" {
  description = "The GCP zone for resources"
  type        = string
  default     = "asia-southeast2-a"
  validation {
    condition     = can(regex("^asia-southeast2-[a-c]$", var.zone))
    error_message = "Zone must be a valid Jakarta zone (asia-southeast2-a, asia-southeast2-b, or asia-southeast2-c)."
  }
}

variable "db_password" {
  description = "Password for the PostgreSQL database"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "node_count" {
  description = "Initial number of GKE nodes"
  type        = number
  default     = 2
  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "node_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", "e2-standard-2", "e2-standard-4",
      "n1-standard-1", "n1-standard-2", "n1-standard-4",
      "n2-standard-2", "n2-standard-4"
    ], var.node_machine_type)
    error_message = "Machine type must be a valid GCP machine type."
  }
}

variable "enable_preemptible" {
  description = "Use preemptible instances to reduce costs"
  type        = bool
  default     = true
}

variable "postgres_tier" {
  description = "Cloud SQL tier for PostgreSQL"
  type        = string
  default     = "db-f1-micro"
  validation {
    condition = contains([
      "db-f1-micro", "db-g1-small", "db-n1-standard-1", "db-n1-standard-2"
    ], var.postgres_tier)
    error_message = "PostgreSQL tier must be a valid Cloud SQL tier."
  }
}

variable "postgres_disk_size" {
  description = "Disk size in GB for PostgreSQL"
  type        = number
  default     = 20
  validation {
    condition     = var.postgres_disk_size >= 10 && var.postgres_disk_size <= 1000
    error_message = "PostgreSQL disk size must be between 10 and 1000 GB."
  }
}

variable "redis_memory_size_gb" {
  description = "Memory size in GB for Redis"
  type        = number
  default     = 1
  validation {
    condition     = var.redis_memory_size_gb >= 1 && var.redis_memory_size_gb <= 300
    error_message = "Redis memory size must be between 1 and 300 GB."
  }
}

variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 1 and 365 days."
  }
}

variable "storage_bucket_name" {
  description = "Name for the Cloud Storage bucket (will be prefixed with project ID)"
  type        = string
  default     = "medusa-uploads"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.storage_bucket_name))
    error_message = "Storage bucket name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "ssl_certificates" {
  description = "List of SSL certificate domains"
  type        = list(string)
  default     = []
}

variable "cors_origins" {
  description = "CORS origins for the application"
  type        = list(string)
  default     = ["http://localhost:3000", "http://localhost:9000"]
}

variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.labels : can(regex("^[a-z0-9_-]+$", k)) && can(regex("^[a-z0-9_-]+$", v))
    ])
    error_message = "Labels must contain only lowercase letters, numbers, underscores, and hyphens."
  }
}