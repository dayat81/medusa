output "vpc_id" {
  description = "VPC network ID"
  value       = google_compute_network.medusa_vpc.id
}

output "vpc_name" {
  description = "VPC network name"
  value       = google_compute_network.medusa_vpc.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.medusa_subnet.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = google_compute_subnetwork.medusa_subnet.name
}

output "private_vpc_connection" {
  description = "Private VPC connection"
  value       = google_service_networking_connection.private_vpc_connection
}

output "vpc_connector_id" {
  description = "VPC Access Connector ID"
  value       = var.skip_vpc_connector ? null : google_vpc_access_connector.connector[0].id
}

output "vpc_connector_name" {
  description = "VPC Access Connector name"
  value       = var.skip_vpc_connector ? null : google_vpc_access_connector.connector[0].name
}