# Cloud Storage bucket for file uploads
resource "google_storage_bucket" "medusa_uploads" {
  name          = "medusa-uploads-${var.project_id}-${var.environment}"
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  force_destroy              = var.environment != "prod"

  versioning {
    enabled = var.environment == "prod"
  }

  cors {
    origin          = var.allowed_origins
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age                   = 2555 # 7 years
      with_state           = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  # Delete incomplete multipart uploads after 1 day
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  labels = {
    environment = var.environment
    component   = "storage"
    service     = "medusa"
  }
}

# Public access for product images (optional - can be restricted)
resource "google_storage_bucket_iam_member" "public_access" {
  count  = var.enable_public_access ? 1 : 0
  bucket = google_storage_bucket.medusa_uploads.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Bucket for backups
resource "google_storage_bucket" "medusa_backups" {
  count         = var.environment == "prod" ? 1 : 0
  name          = "medusa-backups-${var.project_id}-${var.environment}"
  location      = var.region
  project       = var.project_id
  storage_class = "NEARLINE"

  uniform_bucket_level_access = true
  force_destroy              = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  lifecycle_rule {
    condition {
      age = 2555 # 7 years
    }
    action {
      type = "Delete"
    }
  }

  labels = {
    environment = var.environment
    component   = "backup"
    service     = "medusa"
  }
}

# Bucket for static assets (optional)
resource "google_storage_bucket" "medusa_static" {
  name          = "medusa-static-${var.project_id}-${var.environment}"
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  force_destroy              = var.environment != "prod"

  cors {
    origin          = var.allowed_origins
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 86400
  }

  labels = {
    environment = var.environment
    component   = "static"
    service     = "medusa"
  }
}

# Public access for static assets (conditional)
resource "google_storage_bucket_iam_member" "static_public_access" {
  count  = var.enable_public_access ? 1 : 0
  bucket = google_storage_bucket.medusa_static.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Secret for S3-compatible storage configuration
resource "google_secret_manager_secret" "storage_config" {
  secret_id = "medusa-storage-config-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "storage"
  }
}

resource "google_secret_manager_secret_version" "storage_config_version" {
  secret = google_secret_manager_secret.storage_config.id

  secret_data = jsonencode({
    bucket_name    = google_storage_bucket.medusa_uploads.name
    static_bucket  = google_storage_bucket.medusa_static.name
    backup_bucket  = var.environment == "prod" ? google_storage_bucket.medusa_backups[0].name : ""
    region         = var.region
    endpoint       = "https://storage.googleapis.com"
  })
}