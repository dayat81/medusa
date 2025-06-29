# Global static IP address
resource "google_compute_global_address" "medusa_lb_ip" {
  name    = "medusa-lb-ip-${var.environment}"
  project = var.project_id
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "medusa_cert" {
  count = length(var.domains) > 0 ? 1 : 0
  name  = "medusa-cert-${var.environment}"

  managed {
    domains = var.domains
  }

  project = var.project_id

  lifecycle {
    create_before_destroy = true
  }
}

# Network Endpoint Group for Cloud Run
resource "google_compute_region_network_endpoint_group" "medusa_neg" {
  name                  = "medusa-neg-${var.environment}"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  project               = var.project_id

  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Health check
resource "google_compute_health_check" "medusa_health" {
  name    = "medusa-health-check-${var.environment}"
  project = var.project_id

  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 9000
    request_path = "/health"
  }
}

# Backend service
resource "google_compute_backend_service" "medusa_backend" {
  name                  = "medusa-backend-${var.environment}"
  project               = var.project_id
  protocol              = "HTTP"
  timeout_sec           = 30
  enable_cdn            = var.enable_cdn
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.medusa_neg.id
  }

  dynamic "cdn_policy" {
    for_each = var.enable_cdn ? [1] : []
    content {
      cache_mode                   = "CACHE_ALL_STATIC"
      signed_url_cache_max_age_sec = 7200
      default_ttl                  = 3600
      max_ttl                      = 86400
      client_ttl                   = 3600
      negative_caching             = true
      
      negative_caching_policy {
        code = 404
        ttl  = 300
      }
      
      negative_caching_policy {
        code = 410
        ttl  = 300
      }

      cache_key_policy {
        include_host           = true
        include_protocol       = true
        include_query_string   = false
        include_http_headers   = ["Authorization"]
        query_string_whitelist = ["page", "limit", "sort"]
      }
    }
  }

  health_checks = [google_compute_health_check.medusa_health.id]

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  security_policy = var.enable_security_policy ? google_compute_security_policy.medusa_security_policy[0].id : null
}

# URL Map
resource "google_compute_url_map" "medusa_url_map" {
  name            = "medusa-url-map-${var.environment}"
  project         = var.project_id
  default_service = google_compute_backend_service.medusa_backend.id

  host_rule {
    hosts        = length(var.domains) > 0 ? var.domains : ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.medusa_backend.id

    # API routes
    path_rule {
      paths   = ["/admin/*", "/store/*", "/auth/*", "/hooks/*"]
      service = google_compute_backend_service.medusa_backend.id
    }

    # Health check
    path_rule {
      paths   = ["/health"]
      service = google_compute_backend_service.medusa_backend.id
    }

    # Static files
    path_rule {
      paths   = ["/uploads/*", "/static/*"]
      service = google_compute_backend_service.medusa_backend.id
    }
  }
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "medusa_https_proxy" {
  count   = length(var.domains) > 0 ? 1 : 0
  name    = "medusa-https-proxy-${var.environment}"
  project = var.project_id

  url_map          = google_compute_url_map.medusa_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.medusa_cert[0].id]
}

# HTTP Proxy (for redirect to HTTPS)
resource "google_compute_target_http_proxy" "medusa_http_proxy" {
  name    = "medusa-http-proxy-${var.environment}"
  project = var.project_id
  url_map = google_compute_url_map.medusa_redirect.id
}

# URL Map for HTTP to HTTPS redirect
resource "google_compute_url_map" "medusa_redirect" {
  name    = "medusa-redirect-${var.environment}"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

# Global forwarding rule for HTTPS
resource "google_compute_global_forwarding_rule" "medusa_https_forwarding_rule" {
  count      = length(var.domains) > 0 ? 1 : 0
  name       = "medusa-https-forwarding-rule-${var.environment}"
  project    = var.project_id
  target     = google_compute_target_https_proxy.medusa_https_proxy[0].id
  port_range = "443"
  ip_address = google_compute_global_address.medusa_lb_ip.address
}

# Global forwarding rule for HTTP
resource "google_compute_global_forwarding_rule" "medusa_http_forwarding_rule" {
  name       = "medusa-http-forwarding-rule-${var.environment}"
  project    = var.project_id
  target     = google_compute_target_http_proxy.medusa_http_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.medusa_lb_ip.address
}

# Security Policy (optional)
resource "google_compute_security_policy" "medusa_security_policy" {
  count   = var.enable_security_policy ? 1 : 0
  name    = "medusa-security-policy-${var.environment}"
  project = var.project_id

  description = "Security policy for Medusa ${var.environment}"

  # Allow all by default
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }

  # Rate limiting rule
  rule {
    action   = "throttle"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limit rule"
  }

  # Block common attack patterns
  rule {
    action   = "deny(403)"
    priority = "500"
    match {
      expr {
        expression = "request.headers['user-agent'].contains('sqlmap') || request.headers['user-agent'].contains('nikto') || request.headers['user-agent'].contains('nmap')"
      }
    }
    description = "Block malicious user agents"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}