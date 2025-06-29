# Medusa GCP Deployment Plan with Terraform

## Overview

This document outlines a comprehensive plan for deploying Medusa, an open-source composable commerce platform, on Google Cloud Platform (GCP) using Terraform. The deployment will use modern GCP services to ensure scalability, reliability, and maintainability.

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Cloud CDN     │────▶│  Load Balancer   │────▶│   Cloud Run     │
│ (Static Assets) │     │  (HTTPS/Health)  │     │  (Server App)   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                           │
                                ┌──────────────────────────┴───────────────┐
                                │                                          │
                                ▼                                          ▼
                    ┌──────────────────┐                      ┌──────────────────┐
                    │   Cloud SQL      │                      │   Memorystore    │
                    │  (PostgreSQL)    │                      │    (Redis)       │
                    └──────────────────┘                      └──────────────────┘
                                ▲                                          ▲
                                │                                          │
                    ┌───────────┴──────────┐                              │
                    │   Cloud Run          │──────────────────────────────┘
                    │  (Worker App)        │
                    └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │   Cloud Storage      │
                    │  (File Uploads)      │
                    └──────────────────────┘
```

## Prerequisites

### Local Requirements
- Terraform >= 1.5.0
- Google Cloud SDK (gcloud CLI)
- Docker
- Node.js 20+ (for building Medusa)

### GCP Requirements
- GCP Project with billing enabled
- APIs enabled:
  - Cloud Run API
  - Cloud SQL Admin API
  - Cloud Storage API
  - Memorystore Redis API
  - Cloud Build API
  - Artifact Registry API
  - Cloud Load Balancing API
  - Cloud CDN API

### Initial Setup Commands
```bash
# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable \
  run.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  redis.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  compute.googleapis.com
```

## Terraform Module Structure

```
medusa-infra/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── terraform.tfvars        # Variable values (gitignored)
├── modules/
│   ├── networking/         # VPC, subnets, firewall rules
│   ├── database/           # Cloud SQL PostgreSQL
│   ├── redis/              # Memorystore Redis
│   ├── storage/            # Cloud Storage buckets
│   ├── cloudrun/           # Cloud Run services
│   ├── loadbalancer/       # Load balancer & CDN
│   └── iam/                # Service accounts & permissions
└── environments/
    ├── dev/                # Development environment
    ├── staging/            # Staging environment
    └── prod/               # Production environment
```

## Infrastructure Components

### 1. Networking Module

**Resources:**
- VPC with custom subnets
- Cloud NAT for outbound connectivity
- Private service connections for Cloud SQL and Memorystore
- Firewall rules

**Key Configurations:**
```hcl
# VPC for private communication
resource "google_compute_network" "medusa_vpc" {
  name                    = "medusa-vpc"
  auto_create_subnetworks = false
}

# Subnet for Cloud Run
resource "google_compute_subnetwork" "medusa_subnet" {
  name          = "medusa-subnet"
  network       = google_compute_network.medusa_vpc.id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
}

# Private service access for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "medusa-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.medusa_vpc.id
}
```

### 2. Database Module (Cloud SQL PostgreSQL)

**Resources:**
- Cloud SQL PostgreSQL instance
- Database and user creation
- Backup configuration
- High availability setup (for production)

**Key Configurations:**
```hcl
resource "google_sql_database_instance" "medusa_db" {
  name             = "medusa-postgres-${var.environment}"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = var.db_tier # db-f1-micro for dev, db-custom-2-4096 for prod
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }
    
    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }
    
    database_flags {
      name  = "max_connections"
      value = "200"
    }
  }
}

resource "google_sql_database" "medusa" {
  name     = "medusa"
  instance = google_sql_database_instance.medusa_db.name
}
```

### 3. Redis Module (Memorystore)

**Resources:**
- Memorystore Redis instance
- VPC connector for Cloud Run access

**Key Configurations:**
```hcl
resource "google_redis_instance" "medusa_redis" {
  name           = "medusa-redis-${var.environment}"
  tier           = var.redis_tier # BASIC or STANDARD_HA
  memory_size_gb = var.redis_memory

  location_id             = var.zone
  alternative_location_id = var.alternative_zone # For HA

  authorized_network = var.vpc_id
  
  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }
}
```

### 4. Storage Module (Cloud Storage)

**Resources:**
- Cloud Storage bucket for file uploads
- IAM permissions for Cloud Run access
- Lifecycle policies for old files

**Key Configurations:**
```hcl
resource "google_storage_bucket" "medusa_uploads" {
  name          = "medusa-uploads-${var.project_id}-${var.environment}"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  
  cors {
    origin          = var.allowed_origins
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
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
}
```

### 5. Cloud Run Module

**Resources:**
- Cloud Run service for Medusa server
- Cloud Run service for Medusa worker
- VPC connector for private resource access
- Service accounts with appropriate permissions

**Server Configuration:**
```hcl
resource "google_cloud_run_service" "medusa_server" {
  name     = "medusa-server-${var.environment}"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.medusa_server.email
      
      containers {
        image = "${var.artifact_registry_url}/medusa-server:${var.image_tag}"
        
        ports {
          container_port = 9000
        }
        
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        
        env {
          name  = "MEDUSA_WORKER_MODE"
          value = "server"
        }
        
        env {
          name = "DATABASE_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_url.secret_id
              key  = "latest"
            }
          }
        }
        
        env {
          name = "REDIS_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.redis_url.secret_id
              key  = "latest"
            }
          }
        }
        
        resources {
          limits = {
            cpu    = var.server_cpu
            memory = var.server_memory
          }
        }
      }
    }
    
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        "autoscaling.knative.dev/minScale"        = var.server_min_instances
        "autoscaling.knative.dev/maxScale"        = var.server_max_instances
      }
    }
  }
}
```

**Worker Configuration:**
```hcl
resource "google_cloud_run_service" "medusa_worker" {
  name     = "medusa-worker-${var.environment}"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.medusa_worker.email
      
      containers {
        image = "${var.artifact_registry_url}/medusa-worker:${var.image_tag}"
        
        env {
          name  = "MEDUSA_WORKER_MODE"
          value = "worker"
        }
        
        env {
          name  = "DISABLE_MEDUSA_ADMIN"
          value = "true"
        }
        
        # Same database and Redis configuration as server
      }
    }
  }
}
```

### 6. Load Balancer & CDN Module

**Resources:**
- Global load balancer
- SSL certificates
- Cloud CDN configuration
- Health checks

**Key Configurations:**
```hcl
resource "google_compute_global_address" "medusa_lb_ip" {
  name = "medusa-lb-ip-${var.environment}"
}

resource "google_compute_managed_ssl_certificate" "medusa_cert" {
  name = "medusa-cert-${var.environment}"

  managed {
    domains = var.domains
  }
}

resource "google_compute_backend_service" "medusa_backend" {
  name = "medusa-backend-${var.environment}"

  backend {
    group = google_compute_region_network_endpoint_group.medusa_neg.id
  }

  cdn_policy {
    cache_mode = "CACHE_ALL_STATIC"
    
    cache_key_policy {
      include_host         = true
      include_protocol     = true
      include_query_string = false
    }
  }

  health_checks = [google_compute_health_check.medusa_health.id]
}
```

### 7. IAM Module

**Resources:**
- Service accounts for Cloud Run services
- IAM bindings for resource access
- Secret Manager for sensitive data

**Key Configurations:**
```hcl
resource "google_service_account" "medusa_server" {
  account_id   = "medusa-server-${var.environment}"
  display_name = "Medusa Server Service Account"
}

# Permissions for server
resource "google_project_iam_member" "server_permissions" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/storage.objectAdmin",
    "roles/secretmanager.secretAccessor",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.medusa_server.email}"
}
```

## Environment Variables Management

### Secret Manager Configuration
```hcl
# Database URL secret
resource "google_secret_manager_secret" "db_url" {
  secret_id = "medusa-db-url-${var.environment}"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_url_version" {
  secret = google_secret_manager_secret.db_url.id
  
  secret_data = "postgresql://${var.db_user}:${var.db_password}@${google_sql_database_instance.medusa_db.private_ip_address}:5432/${var.db_name}"
}

# Redis URL secret
resource "google_secret_manager_secret" "redis_url" {
  secret_id = "medusa-redis-url-${var.environment}"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "redis_url_version" {
  secret = google_secret_manager_secret.redis_url.id
  
  secret_data = "redis://${google_redis_instance.medusa_redis.host}:${google_redis_instance.medusa_redis.port}"
}
```

## Deployment Process

### 1. Build and Push Docker Images

```bash
# Build server image
docker build -f Dockerfile.server -t medusa-server:latest .

# Build worker image
docker build -f Dockerfile.worker -t medusa-worker:latest .

# Tag and push to Artifact Registry
docker tag medusa-server:latest ${REGION}-docker.pkg.dev/${PROJECT_ID}/medusa/server:${VERSION}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/medusa/server:${VERSION}

docker tag medusa-worker:latest ${REGION}-docker.pkg.dev/${PROJECT_ID}/medusa/worker:${VERSION}
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/medusa/worker:${VERSION}
```

### 2. Terraform Deployment

```bash
# Initialize Terraform
cd terraform/environments/prod
terraform init

# Plan deployment
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Run database migrations
gcloud run jobs execute medusa-migrate --region=${REGION}
```

### 3. Post-Deployment Steps

1. **Verify Health Checks**
   ```bash
   curl https://your-domain.com/health
   ```

2. **Configure DNS**
   - Point your domain to the load balancer IP
   - Wait for SSL certificate provisioning

3. **Set up Monitoring**
   - Configure Cloud Monitoring dashboards
   - Set up alerting policies
   - Enable Cloud Logging

## Cost Optimization

### Development Environment
- Use minimal resources (f1-micro instances)
- Single zone deployment
- No high availability

### Production Environment
- Right-size instances based on load
- Use committed use discounts
- Enable autoscaling with appropriate limits
- Use Cloud CDN for static assets

### Estimated Monthly Costs

**Development:**
- Cloud Run: ~$10-20
- Cloud SQL (f1-micro): ~$15
- Memorystore (1GB): ~$35
- Storage & Network: ~$10
- **Total: ~$70-80/month**

**Production (Medium Load):**
- Cloud Run (2-10 instances): ~$100-300
- Cloud SQL (2 vCPU, 8GB, HA): ~$250
- Memorystore (5GB, HA): ~$250
- Storage & Network: ~$50-100
- **Total: ~$650-900/month**

## Security Considerations

### Network Security
- All services in private VPC
- No public IPs on databases
- Cloud Armor for DDoS protection
- Identity-Aware Proxy for admin access

### Data Security
- Encryption at rest for all services
- TLS 1.2+ for all connections
- Secrets in Secret Manager
- Regular security scans

### Access Control
- Least privilege IAM policies
- Service accounts for each component
- Audit logging enabled
- MFA for GCP console access

## Monitoring and Maintenance

### Key Metrics to Monitor
- Cloud Run request latency and errors
- Database connections and query performance
- Redis memory usage and evictions
- Storage bucket size and request rates

### Maintenance Tasks
- Weekly database backups verification
- Monthly security updates
- Quarterly cost optimization review
- Annual disaster recovery testing

## Disaster Recovery

### Backup Strategy
- Automated daily database backups
- Point-in-time recovery for 7 days
- Cross-region backup replication
- Storage bucket versioning

### Recovery Procedures
1. **Database Failure**: Restore from backup or failover to replica
2. **Region Failure**: Deploy to secondary region using Terraform
3. **Data Corruption**: Restore from point-in-time recovery
4. **Service Outage**: Auto-healing with Cloud Run

## CI/CD Integration

### GitHub Actions Workflow
```yaml
name: Deploy to GCP
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
      
      - name: Build and Push Images
        run: |
          docker build -f Dockerfile.server -t medusa-server .
          docker build -f Dockerfile.worker -t medusa-worker .
          
          docker tag medusa-server ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/server:${{ github.sha }}
          docker tag medusa-worker ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/worker:${{ github.sha }}
          
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/server:${{ github.sha }}
          docker push ${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/worker:${{ github.sha }}
      
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy medusa-server --image=${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/server:${{ github.sha }}
          gcloud run deploy medusa-worker --image=${{ env.REGION }}-docker.pkg.dev/${{ env.PROJECT_ID }}/medusa/worker:${{ github.sha }}
```

## Next Steps

1. **Create Terraform modules** following the structure outlined above
2. **Set up GCP project** with required APIs enabled
3. **Configure secrets** in Secret Manager
4. **Build Docker images** for server and worker
5. **Deploy infrastructure** using Terraform
6. **Run database migrations**
7. **Configure monitoring** and alerting
8. **Test the deployment** thoroughly
9. **Document runbooks** for operations team

## Conclusion

This deployment plan provides a production-ready, scalable infrastructure for Medusa on Google Cloud Platform. The use of Terraform ensures infrastructure as code best practices, while modern GCP services provide reliability and performance. The modular approach allows for easy customization and environment-specific configurations.