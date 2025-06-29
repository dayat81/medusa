output "ip_address" {
  description = "Load balancer IP address"
  value       = google_compute_global_address.medusa_lb_ip.address
}

output "url" {
  description = "Load balancer URL"
  value       = length(var.domains) > 0 ? "https://${var.domains[0]}" : "http://${google_compute_global_address.medusa_lb_ip.address}"
}

output "ssl_certificate_id" {
  description = "SSL certificate ID"
  value       = length(var.domains) > 0 ? google_compute_managed_ssl_certificate.medusa_cert[0].id : null
}

output "backend_service_id" {
  description = "Backend service ID"
  value       = google_compute_backend_service.medusa_backend.id
}

output "url_map_id" {
  description = "URL map ID"
  value       = google_compute_url_map.medusa_url_map.id
}

output "https_proxy_id" {
  description = "HTTPS proxy ID"
  value       = length(var.domains) > 0 ? google_compute_target_https_proxy.medusa_https_proxy[0].id : null
}

output "http_proxy_id" {
  description = "HTTP proxy ID"
  value       = google_compute_target_http_proxy.medusa_http_proxy.id
}

output "security_policy_id" {
  description = "Security policy ID"
  value       = var.enable_security_policy ? google_compute_security_policy.medusa_security_policy[0].id : null
}