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

variable "vpc_id" {
  description = "VPC network ID"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection for Cloud SQL"
  default     = null
}

variable "use_private_network" {
  description = "Use private networking for database"
  type        = bool
  default     = false
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
  default     = ""
}

variable "enable_ha" {
  description = "Enable high availability"
  type        = bool
  default     = false
}

variable "backup_start_time" {
  description = "Backup start time (HH:MM)"
  type        = string
  default     = "03:00"
}