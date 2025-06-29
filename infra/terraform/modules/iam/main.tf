# Service Account for Medusa Server
resource "google_service_account" "medusa_server" {
  account_id   = "medusa-server-${var.environment}"
  display_name = "Medusa Server Service Account - ${var.environment}"
  description  = "Service account for Medusa server in ${var.environment} environment"
  project      = var.project_id
}

# Service Account for Medusa Worker
resource "google_service_account" "medusa_worker" {
  account_id   = "medusa-worker-${var.environment}"
  display_name = "Medusa Worker Service Account - ${var.environment}"
  description  = "Service account for Medusa worker in ${var.environment} environment"
  project      = var.project_id
}

# IAM bindings for Server Service Account
resource "google_project_iam_member" "server_permissions" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin",
    "roles/redis.editor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.medusa_server.email}"
}

# IAM bindings for Worker Service Account
resource "google_project_iam_member" "worker_permissions" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin",
    "roles/redis.editor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.medusa_worker.email}"
}

# Custom IAM role for Medusa-specific permissions
resource "google_project_iam_custom_role" "medusa_role" {
  role_id     = "medusaCustomRole${title(var.environment)}"
  title       = "Medusa Custom Role - ${var.environment}"
  description = "Custom role for Medusa application in ${var.environment} environment"
  permissions = [
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.update",
    "secretmanager.versions.access",
    "cloudsql.instances.connect",
    "redis.instances.get"
  ]
}

# Assign custom role to service accounts
resource "google_project_iam_member" "server_custom_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.medusa_role.id
  member  = "serviceAccount:${google_service_account.medusa_server.email}"
}

resource "google_project_iam_member" "worker_custom_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.medusa_role.id
  member  = "serviceAccount:${google_service_account.medusa_worker.email}"
}

# Service Account for Cloud Build (if using CI/CD)
resource "google_service_account" "cloudbuild" {
  count        = var.enable_cicd ? 1 : 0
  account_id   = "medusa-cloudbuild-${var.environment}"
  display_name = "Medusa Cloud Build Service Account - ${var.environment}"
  description  = "Service account for Cloud Build in ${var.environment} environment"
  project      = var.project_id
}

# IAM bindings for Cloud Build Service Account
resource "google_project_iam_member" "cloudbuild_permissions" {
  for_each = var.enable_cicd ? toset([
    "roles/cloudbuild.builds.builder",
    "roles/artifactregistry.writer",
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin"
  ]) : toset([])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudbuild[0].email}"
}

# Workload Identity binding for GitHub Actions (if using GitHub Actions)
resource "google_service_account_iam_member" "github_actions_workload_identity" {
  count              = var.enable_github_actions ? 1 : 0
  service_account_id = google_service_account.medusa_server.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${var.github_workload_identity_pool}/attribute.repository/${var.github_repository}"
}

# Get project data
data "google_project" "project" {
  project_id = var.project_id
}

# Secret Manager IAM for specific secrets
resource "google_secret_manager_secret_iam_member" "server_secret_access" {
  for_each = toset(var.secret_ids)

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.medusa_server.email}"
}

resource "google_secret_manager_secret_iam_member" "worker_secret_access" {
  for_each = toset(var.secret_ids)

  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.medusa_worker.email}"
}

# Storage bucket IAM for specific buckets
resource "google_storage_bucket_iam_member" "server_bucket_access" {
  for_each = toset(var.storage_buckets)

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.medusa_server.email}"
}

resource "google_storage_bucket_iam_member" "worker_bucket_access" {
  for_each = toset(var.storage_buckets)

  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.medusa_worker.email}"
}

# IAM Audit Config
resource "google_project_iam_audit_config" "audit_config" {
  project = var.project_id
  service = "cloudsql.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Monitoring IAM for service accounts to write metrics
resource "google_project_iam_member" "server_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.medusa_server.email}"
}

resource "google_project_iam_member" "worker_monitoring_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.medusa_worker.email}"
}