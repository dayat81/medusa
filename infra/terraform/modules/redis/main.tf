# Memorystore Redis instance
resource "google_redis_instance" "medusa_redis" {
  name           = "medusa-redis-${var.environment}"
  tier           = var.redis_tier
  memory_size_gb = var.redis_memory_gb
  region         = var.region
  project        = var.project_id

  location_id             = var.zone
  alternative_location_id = var.enable_ha ? var.alternative_zone : null

  authorized_network   = var.use_private_network ? var.vpc_id : null
  connect_mode         = var.use_private_network ? "PRIVATE_SERVICE_ACCESS" : "DIRECT_PEERING"
  redis_version        = "REDIS_6_X"
  display_name         = "Medusa Redis ${var.environment}"

  redis_configs = {
    maxmemory-policy = "allkeys-lru"
    timeout         = "300"
  }

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels = {
    environment = var.environment
    component   = "cache"
    service     = "medusa"
  }
}

# Secret for Redis URL
resource "google_secret_manager_secret" "redis_url" {
  secret_id = "medusa-redis-url-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "redis"
  }
}

resource "google_secret_manager_secret_version" "redis_url_version" {
  secret = google_secret_manager_secret.redis_url.id

  secret_data = "redis://${google_redis_instance.medusa_redis.host}:${google_redis_instance.medusa_redis.port}"
}

# Secret for Redis connection details
resource "google_secret_manager_secret" "redis_config" {
  secret_id = "medusa-redis-config-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "redis"
  }
}

resource "google_secret_manager_secret_version" "redis_config_version" {
  secret = google_secret_manager_secret.redis_config.id

  secret_data = jsonencode({
    host = google_redis_instance.medusa_redis.host
    port = google_redis_instance.medusa_redis.port
  })
}