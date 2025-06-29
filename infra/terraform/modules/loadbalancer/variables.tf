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

variable "cloud_run_service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "cloud_run_service_url" {
  description = "Cloud Run service URL"
  type        = string
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

variable "enable_security_policy" {
  description = "Enable Cloud Armor security policy"
  type        = bool
  default     = true
}