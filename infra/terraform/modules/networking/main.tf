# VPC Network
resource "google_compute_network" "medusa_vpc" {
  name                    = "medusa-vpc-${var.environment}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "medusa_subnet" {
  name          = "medusa-subnet-${var.environment}"
  network       = google_compute_network.medusa_vpc.id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  project       = var.project_id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.1.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.64.0/22"
  }
}

# Global address for private services
resource "google_compute_global_address" "private_ip_address" {
  name          = "medusa-private-ip-${var.environment}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.medusa_vpc.id
  project       = var.project_id
}

# Private connection for services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.medusa_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud NAT Router
resource "google_compute_router" "medusa_router" {
  name    = "medusa-router-${var.environment}"
  region  = var.region
  network = google_compute_network.medusa_vpc.id
  project = var.project_id
}

# Cloud NAT
resource "google_compute_router_nat" "medusa_nat" {
  name                               = "medusa-nat-${var.environment}"
  router                             = google_compute_router.medusa_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# VPC Access Connector for Cloud Run (conditional)
resource "google_vpc_access_connector" "connector" {
  count         = var.skip_vpc_connector ? 0 : 1
  name          = "medusa-connector-${var.environment}"
  region        = var.region
  network       = google_compute_network.medusa_vpc.name
  ip_cidr_range = "10.8.0.0/28"
  project       = var.project_id
  
  min_instances = 2
  max_instances = 10
  
  machine_type = "e2-micro"
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "medusa-allow-internal-${var.environment}"
  network = google_compute_network.medusa_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "medusa-allow-health-check-${var.environment}"
  network = google_compute_network.medusa_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "9000"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["medusa-health-check"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "medusa-allow-ssh-${var.environment}"
  network = google_compute_network.medusa_vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
}