variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_cicd" {
  description = "Enable CI/CD service account and permissions"
  type        = bool
  default     = false
}

variable "enable_github_actions" {
  description = "Enable GitHub Actions workload identity"
  type        = bool
  default     = false
}

variable "github_workload_identity_pool" {
  description = "GitHub workload identity pool ID"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = ""
}

variable "secret_ids" {
  description = "List of Secret Manager secret IDs to grant access to"
  type        = list(string)
  default     = []
}

variable "storage_buckets" {
  description = "List of storage bucket names to grant access to"
  type        = list(string)
  default     = []
}