# Medusa Server Cloud Run Service
resource "google_cloud_run_service" "medusa_server" {
  name     = "medusa-server-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    metadata {
      annotations = merge(
        {
          "autoscaling.knative.dev/minScale"        = var.server_min_instances
          "autoscaling.knative.dev/maxScale"        = var.server_max_instances
          "run.googleapis.com/execution-environment" = "gen2"
          "run.googleapis.com/cpu-throttling"       = "false"
          "run.googleapis.com/cloudsql-instances"   = var.db_connection_name
        },
        var.vpc_connector_id != null ? {
          "run.googleapis.com/vpc-access-connector" = var.vpc_connector_id
        } : {}
      )
      labels = {
        environment = var.environment
        component   = "server"
        service     = "medusa"
        version     = var.image_tag
      }
    }

    spec {
      service_account_name  = var.server_service_account
      container_concurrency = 100
      timeout_seconds       = 300

      containers {
        image = "${var.artifact_registry_url}/medusa-server:${var.image_tag}"

        ports {
          name           = "http1"
          container_port = 9000
          protocol       = "TCP"
        }

        resources {
          limits = {
            cpu    = var.server_cpu
            memory = var.server_memory
          }
        }

        # Environment variables
        env {
          name  = "NODE_ENV"
          value = "production"
        }

        env {
          name  = "MEDUSA_WORKER_MODE"
          value = "server"
        }

        env {
          name  = "PORT"
          value = "9000"
        }

        env {
          name  = "DISABLE_MEDUSA_ADMIN"
          value = "false"
        }

        # Database connection
        env {
          name = "DATABASE_URL"
          value_from {
            secret_key_ref {
              name = var.db_url_secret_id
              key  = "latest"
            }
          }
        }

        # Redis connection
        env {
          name = "REDIS_URL"
          value_from {
            secret_key_ref {
              name = var.redis_url_secret_id
              key  = "latest"
            }
          }
        }

        # Storage configuration
        env {
          name  = "GCS_BUCKET"
          value = var.storage_bucket_name
        }

        env {
          name  = "GCS_PROJECT_ID"
          value = var.project_id
        }

        # CORS configuration
        env {
          name  = "STORE_CORS"
          value = join(",", var.allowed_origins)
        }

        env {
          name  = "ADMIN_CORS"
          value = join(",", var.allowed_origins)
        }

        env {
          name  = "AUTH_CORS"
          value = join(",", var.allowed_origins)
        }

        # Secrets
        env {
          name = "COOKIE_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.cookie_secret.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "JWT_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.jwt_secret.secret_id
              key  = "latest"
            }
          }
        }

        # Health check
        liveness_probe {
          http_get {
            path = "/health"
            port = 9000
          }
          initial_delay_seconds = 30
          period_seconds        = 30
          timeout_seconds       = 10
          failure_threshold     = 3
        }

        startup_probe {
          http_get {
            path = "/health"
            port = 9000
          }
          initial_delay_seconds = 30
          period_seconds        = 10
          timeout_seconds       = 10
          failure_threshold     = 10
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/operation-id"]
    ]
  }
}

# Medusa Worker Cloud Run Service
resource "google_cloud_run_service" "medusa_worker" {
  name     = "medusa-worker-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    metadata {
      annotations = merge(
        {
          "autoscaling.knative.dev/minScale"        = var.worker_min_instances
          "autoscaling.knative.dev/maxScale"        = var.worker_max_instances
          "run.googleapis.com/execution-environment" = "gen2"
          "run.googleapis.com/cpu-throttling"       = "false"
          "run.googleapis.com/cloudsql-instances"   = var.db_connection_name
        },
        var.vpc_connector_id != null ? {
          "run.googleapis.com/vpc-access-connector" = var.vpc_connector_id
        } : {}
      )
      labels = {
        environment = var.environment
        component   = "worker"
        service     = "medusa"
        version     = var.image_tag
      }
    }

    spec {
      service_account_name  = var.worker_service_account
      container_concurrency = 1
      timeout_seconds       = 3600

      containers {
        image = "${var.artifact_registry_url}/medusa-worker:${var.image_tag}"

        resources {
          limits = {
            cpu    = var.worker_cpu
            memory = var.worker_memory
          }
        }

        # Environment variables
        env {
          name  = "NODE_ENV"
          value = "production"
        }

        env {
          name  = "MEDUSA_WORKER_MODE"
          value = "worker"
        }

        env {
          name  = "DISABLE_MEDUSA_ADMIN"
          value = "true"
        }

        # Database connection
        env {
          name = "DATABASE_URL"
          value_from {
            secret_key_ref {
              name = var.db_url_secret_id
              key  = "latest"
            }
          }
        }

        # Redis connection
        env {
          name = "REDIS_URL"
          value_from {
            secret_key_ref {
              name = var.redis_url_secret_id
              key  = "latest"
            }
          }
        }

        # Storage configuration
        env {
          name  = "GCS_BUCKET"
          value = var.storage_bucket_name
        }

        env {
          name  = "GCS_PROJECT_ID"
          value = var.project_id
        }

        # Secrets
        env {
          name = "COOKIE_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.cookie_secret.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "JWT_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.jwt_secret.secret_id
              key  = "latest"
            }
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  lifecycle {
    ignore_changes = [
      template[0].metadata[0].annotations["run.googleapis.com/operation-id"]
    ]
  }
}

# IAM policy for server service to allow public access
resource "google_cloud_run_service_iam_member" "server_public_access" {
  service  = google_cloud_run_service.medusa_server.name
  location = google_cloud_run_service.medusa_server.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Generate random secrets
resource "random_password" "cookie_secret" {
  length  = 32
  special = true
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# Secret for cookie secret
resource "google_secret_manager_secret" "cookie_secret" {
  secret_id = "medusa-cookie-secret-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "auth"
  }
}

resource "google_secret_manager_secret_version" "cookie_secret_version" {
  secret = google_secret_manager_secret.cookie_secret.id

  secret_data = random_password.cookie_secret.result
}

# Secret for JWT secret
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "medusa-jwt-secret-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "auth"
  }
}

resource "google_secret_manager_secret_version" "jwt_secret_version" {
  secret = google_secret_manager_secret.jwt_secret.id

  secret_data = random_password.jwt_secret.result
}