# Medusa Terraform Infrastructure

This directory contains Terraform configurations to deploy Medusa on Google Cloud Platform (GCP).

## Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── versions.tf             # Provider versions
├── modules/                # Reusable modules
│   ├── networking/         # VPC, subnets, firewall
│   ├── database/           # Cloud SQL PostgreSQL
│   ├── redis/              # Memorystore Redis
│   ├── storage/            # Cloud Storage buckets
│   ├── cloudrun/           # Cloud Run services
│   ├── loadbalancer/       # Load balancer & CDN
│   └── iam/                # Service accounts & permissions
└── environments/           # Environment-specific configs
    ├── dev/                # Development
    ├── staging/            # Staging
    └── prod/               # Production
```

## Prerequisites

1. **GCP Project Setup**
   ```bash
   # Set your project
   gcloud config set project YOUR_PROJECT_ID
   
   # Enable required APIs
   gcloud services enable \
     run.googleapis.com \
     sqladmin.googleapis.com \
     storage.googleapis.com \
     redis.googleapis.com \
     cloudbuild.googleapis.com \
     artifactregistry.googleapis.com \
     compute.googleapis.com \
     secretmanager.googleapis.com \
     vpcaccess.googleapis.com \
     servicenetworking.googleapis.com
   ```

2. **Terraform State Backend**
   ```bash
   # Create bucket for Terraform state
   gsutil mb gs://your-terraform-state-bucket-dev
   gsutil mb gs://your-terraform-state-bucket-prod
   
   # Enable versioning
   gsutil versioning set on gs://your-terraform-state-bucket-dev
   gsutil versioning set on gs://your-terraform-state-bucket-prod
   ```

3. **Artifact Registry**
   ```bash
   # Create repository for Docker images
   gcloud artifacts repositories create medusa \
     --repository-format=docker \
     --location=us-central1
   ```

## Quick Start

### 1. Development Environment

```bash
cd environments/dev

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Production Environment

```bash
cd environments/prod

# Copy and customize variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your production values

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

## Configuration

### Required Variables

Create a `terraform.tfvars` file in your environment directory:

```hcl
# Basic Configuration
project_id = "your-gcp-project"
environment = "dev"  # or "prod"

# Database
db_password = "secure-random-password"

# Application
artifact_registry_url = "us-central1-docker.pkg.dev/your-project/medusa"

# Domains (production only)
domains = ["yourdomain.com", "www.yourdomain.com"]
allowed_origins = ["https://yourdomain.com"]
```

### Environment Differences

**Development:**
- Minimal resources (f1-micro instances)
- No high availability
- Scale to zero when idle
- Basic monitoring

**Production:**
- High availability enabled
- Larger instances
- Auto-scaling configured
- Enhanced monitoring and security

## Deployment Process

### 1. Infrastructure Deployment

```bash
# Deploy infrastructure
terraform apply

# Note the outputs, especially:
# - Load balancer IP
# - Database connection details
# - Storage bucket names
```

### 2. Application Deployment

```bash
# Build Docker images (from Medusa root directory)
docker build -f Dockerfile.server -t medusa-server .
docker build -f Dockerfile.worker -t medusa-worker .

# Tag and push to Artifact Registry
docker tag medusa-server us-central1-docker.pkg.dev/PROJECT/medusa/server:latest
docker tag medusa-worker us-central1-docker.pkg.dev/PROJECT/medusa/worker:latest

docker push us-central1-docker.pkg.dev/PROJECT/medusa/server:latest
docker push us-central1-docker.pkg.dev/PROJECT/medusa/worker:latest

# Update Cloud Run services (automatically triggered by new images)
```

### 3. Database Setup

```bash
# Run database migrations
gcloud run jobs create medusa-migrate \
  --image=us-central1-docker.pkg.dev/PROJECT/medusa/server:latest \
  --set-env-vars="DATABASE_URL=..." \
  --command="npm,run,db:migrate"

gcloud run jobs execute medusa-migrate
```

### 4. DNS Configuration

```bash
# Point your domain to the load balancer IP
# This is shown in terraform outputs

# For production, update your DNS records:
# A record: yourdomain.com -> LOAD_BALANCER_IP
# CNAME: www.yourdomain.com -> yourdomain.com
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check application health
curl https://yourdomain.com/health

# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=medusa-server-prod"
```

### Database Maintenance

```bash
# Connect to database
gcloud sql connect INSTANCE_NAME --user=medusa

# View backups
gcloud sql backups list --instance=INSTANCE_NAME
```

### Scaling

Update variables in `terraform.tfvars` and re-apply:

```hcl
server_min_instances = 3
server_max_instances = 50
worker_max_instances = 20
```

## Security

### IAM Roles

- **Server Service Account**: Cloud SQL client, Storage admin, Secret accessor
- **Worker Service Account**: Same as server (no public access)
- **Custom Role**: Minimal permissions for Medusa operations

### Network Security

- Private VPC for all resources
- Cloud SQL on private IP only
- VPC Access Connector for Cloud Run
- Cloud Armor for DDoS protection

### Secrets Management

All sensitive data stored in Secret Manager:
- Database credentials
- Redis connection
- Application secrets (JWT, cookies)

## Troubleshooting

### Common Issues

1. **SSL Certificate Provisioning**
   ```bash
   # Check certificate status
   gcloud compute ssl-certificates describe medusa-cert-prod
   
   # Verify DNS pointing to load balancer
   dig yourdomain.com
   ```

2. **Database Connection Issues**
   ```bash
   # Test from Cloud Run
   gcloud run services describe medusa-server-prod
   
   # Check VPC connector
   gcloud compute networks vpc-access connectors describe medusa-connector-prod
   ```

3. **Image Pull Issues**
   ```bash
   # Verify repository permissions
   gcloud artifacts repositories get-iam-policy medusa --location=us-central1
   
   # Check image exists
   gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT/medusa
   ```

### Debugging Commands

```bash
# View Terraform state
terraform state list
terraform state show module.medusa.google_cloud_run_service.medusa_server

# Check resource status
gcloud run services list
gcloud sql instances list
gcloud redis instances list

# View recent deployments
gcloud run revisions list --service=medusa-server-prod
```

## Cost Optimization

### Development
- Use `f1-micro` instances
- Scale to zero when idle
- Disable high availability

### Production
- Use committed use discounts
- Monitor and right-size instances
- Enable Cloud CDN for static assets
- Set up budget alerts

```bash
# Set up budget alerts
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT \
  --display-name="Medusa Infrastructure" \
  --budget-amount=1000USD
```

## Backup and Disaster Recovery

### Automated Backups
- Database: Daily automated backups with 7-day retention
- Storage: Versioning enabled with lifecycle policies
- Terraform state: Stored in versioned GCS buckets

### Recovery Procedures
1. Database restore from backup
2. Re-deploy infrastructure from Terraform
3. Restore application from container images
4. Update DNS if needed

For detailed disaster recovery procedures, see the deployment plan documentation.