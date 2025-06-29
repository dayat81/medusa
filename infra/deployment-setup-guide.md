# Medusa GCP Deployment Setup Guide

## Current Status: Billing Configuration Required

### ⚠️ Action Required

Before continuing with the Medusa deployment, you need to set up billing for the GCP project.

### Step-by-Step Instructions

#### 1. Enable Billing Account

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select project: `medusa-dev-indonesia`

2. **Navigate to Billing**
   - In the left sidebar, click "Billing"
   - Or go directly to: https://console.cloud.google.com/billing

3. **Link Billing Account**
   - Click "Link a billing account"
   - Select an existing billing account OR create a new one
   - If creating new: provide payment method details

4. **Verify Billing is Active**
   - Ensure the project shows "Billing account linked"
   - Status should show "Active"

#### 2. Continue Deployment

After billing is configured, run these commands to continue:

```bash
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
  servicenetworking.googleapis.com \
  --project=medusa-dev-indonesia

# Create Terraform state bucket
gsutil mb -p medusa-dev-indonesia -c STANDARD -l asia-southeast2 gs://medusa-terraform-state-dev-indonesia

# Create Artifact Registry repository
gcloud artifacts repositories create medusa \
  --repository-format=docker \
  --location=asia-southeast2 \
  --project=medusa-dev-indonesia

# Continue with Terraform deployment
cd /home/hek/medusa/infra/terraform/environments/dev
terraform init
terraform plan
terraform apply
```

### Project Configuration Summary

- **Project ID:** medusa-dev-indonesia
- **Project Number:** 423225616449
- **Region:** asia-southeast2 (Jakarta, Indonesia)
- **Environment:** Development

### Infrastructure Components to Deploy

1. **Networking**
   - VPC with private subnets
   - VPC Access Connector
   - Cloud NAT

2. **Database**
   - Cloud SQL PostgreSQL (db-f1-micro)
   - Private IP only
   - Automated backups

3. **Cache**
   - Memorystore Redis (1GB, Basic tier)
   - Private network access

4. **Storage**
   - Cloud Storage buckets for uploads
   - Lifecycle policies

5. **Compute**
   - Cloud Run services (server + worker)
   - Auto-scaling (0-5 instances)
   - 1 vCPU, 1GB RAM each

6. **Load Balancer**
   - Global HTTP(S) Load Balancer
   - Health checks

7. **Security**
   - Service accounts with minimal permissions
   - Secret Manager for credentials
   - Private networking

### Estimated Monthly Costs (Development)

- Cloud Run: $10-20
- Cloud SQL: $15-25  
- Memorystore: $35-45
- Storage & Network: $5-15
- **Total: ~$65-105/month**

### Next Steps After Billing

1. ✅ Complete API enablement
2. ✅ Create infrastructure with Terraform
3. ✅ Build and deploy Docker images
4. ✅ Run database migrations
5. ✅ Test the deployment

For detailed deployment logs, see: `/home/hek/medusa/infra/logs/deployment-log-dev-indonesia.md`