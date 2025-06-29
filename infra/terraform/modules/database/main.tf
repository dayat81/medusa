# Random password for database user
resource "random_password" "db_password" {
  count   = var.db_password == "" ? 1 : 0
  length  = 16
  special = true
}

# Cloud SQL instance
resource "google_sql_database_instance" "medusa_db" {
  name             = "medusa-postgres-${var.environment}"
  database_version = "POSTGRES_14"
  region           = var.region
  project          = var.project_id

  deletion_protection = var.environment == "prod" ? true : false

  settings {
    tier              = var.db_tier
    availability_type = var.enable_ha ? "REGIONAL" : "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = var.environment == "prod" ? 100 : 20
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled       = true
      private_network    = var.use_private_network ? var.vpc_id : null
      require_ssl        = true
      authorized_networks {
        name  = "all-cloud-run"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = var.environment == "prod" ? true : false
      transaction_log_retention_days = var.environment == "prod" ? 7 : 3
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
        retention_unit   = "COUNT"
      }
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = false
      record_client_address   = false
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }


    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }
  }

  depends_on = [var.private_vpc_connection]
  
  lifecycle {
    ignore_changes = [settings[0].ip_configuration[0].authorized_networks]
  }
}

# Database
resource "google_sql_database" "medusa" {
  name     = var.db_name
  instance = google_sql_database_instance.medusa_db.name
  project  = var.project_id
}

# Database user
resource "google_sql_user" "medusa_user" {
  name     = var.db_user
  instance = google_sql_database_instance.medusa_db.name
  password = var.db_password != "" ? var.db_password : random_password.db_password[0].result
  project  = var.project_id
}

# SSL Certificate
resource "google_sql_ssl_cert" "client_cert" {
  common_name = "medusa-${var.environment}"
  instance    = google_sql_database_instance.medusa_db.name
  project     = var.project_id
}

# Secret for database URL
resource "google_secret_manager_secret" "db_url" {
  secret_id = "medusa-db-url-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "database"
  }
}

resource "google_secret_manager_secret_version" "db_url_version" {
  secret = google_secret_manager_secret.db_url.id

  secret_data = var.use_private_network ? "postgresql://${google_sql_user.medusa_user.name}:${google_sql_user.medusa_user.password}@${google_sql_database_instance.medusa_db.private_ip_address}:5432/${google_sql_database.medusa.name}?sslmode=require" : "postgresql://${google_sql_user.medusa_user.name}:${google_sql_user.medusa_user.password}@${google_sql_database_instance.medusa_db.public_ip_address}:5432/${google_sql_database.medusa.name}?sslmode=require"
}

# Secret for database password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "medusa-db-password-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "database"
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret = google_secret_manager_secret.db_password.id

  secret_data = var.db_password != "" ? var.db_password : random_password.db_password[0].result
}