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

variable "skip_vpc_connector" {
  description = "Skip VPC connector creation"
  type        = bool
  default     = false
}