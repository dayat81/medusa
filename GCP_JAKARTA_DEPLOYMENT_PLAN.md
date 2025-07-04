# Medusa E-commerce Platform - GCP Jakarta Deployment Plan

## Overview

This document outlines the comprehensive plan to deploy the Medusa e-commerce platform on Google Cloud Platform (GCP) in the Jakarta region (asia-southeast2) for the development environment.

## 📋 Table of Contents

1. [Project Requirements](#project-requirements)
2. [Infrastructure Architecture](#infrastructure-architecture)
3. [Prerequisites](#prerequisites)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Configuration](#post-deployment-configuration)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)
7. [Cost Optimization](#cost-optimization)
8. [Security Considerations](#security-considerations)
9. [Troubleshooting](#troubleshooting)

## 🎯 Project Requirements

### Medusa Platform Requirements
- **Runtime**: Node.js 20+
- **Database**: PostgreSQL 15
- **Cache**: Redis
- **File Storage**: Cloud Storage
- **Container Orchestration**: Kubernetes (GKE)
- **Load Balancing**: Google Cloud Load Balancer
- **Environment**: Development

### GCP Services Utilized
- **Compute**: Google Kubernetes Engine (GKE)
- **Database**: Cloud SQL for PostgreSQL
- **Cache**: Memorystore for Redis
- **Storage**: Cloud Storage
- **Networking**: VPC, Cloud NAT, Load Balancer
- **Security**: Secret Manager, IAM
- **Container Registry**: Artifact Registry
- **Monitoring**: Cloud Operations Suite

## 🏗️ Infrastructure Architecture

### Network Architecture
```
Internet
    ↓
Google Cloud Load Balancer (Static IP)
    ↓
GKE Cluster (Private Nodes)
    ↓
VPC Network (asia-southeast2)
    ├── Subnet: 10.0.0.0/24 (GKE nodes)
    ├── Secondary Range: 10.1.0.0/16 (Pods)
    ├── Secondary Range: 10.2.0.0/16 (Services)
    └── Private Google Access
        ├── Cloud SQL (PostgreSQL)
        ├── Memorystore (Redis)
        └── Cloud Storage
```

### Component Specifications

#### GKE Cluster
- **Location**: asia-southeast2-a (Jakarta)
- **Node Pool**: 2 x e2-medium instances (preemptible)
- **Autoscaling**: 1-5 nodes
- **Network**: Private cluster with authorized networks
- **Workload Identity**: Enabled for secure GCP service access

#### Database (Cloud SQL)
- **Engine**: PostgreSQL 15
- **Tier**: db-f1-micro (development)
- **Storage**: 20GB SSD with auto-resize
- **Backup**: Daily automated backups (7-day retention)
- **Network**: Private IP only, VPC peering

#### Cache (Memorystore Redis)
- **Version**: Redis 7.0
- **Tier**: Basic (1GB memory)
- **Network**: VPC-native, private access only
- **High Availability**: Single zone for development

#### Storage
- **Bucket**: Regional bucket in asia-southeast2
- **Access**: Uniform bucket-level access
- **Lifecycle**: 30-day deletion policy for old versions

## 🔧 Prerequisites

### 1. GCP Project Setup
- Create a new GCP project or use existing one
- Enable billing for the project
- Install and configure `gcloud` CLI
- Install `terraform` (>= 1.0)
- Install `kubectl`
- Install `docker`

### 2. Required Permissions
Ensure your account has the following IAM roles:
- Project Editor or custom role with:
  - Compute Admin
  - Kubernetes Engine Admin
  - Cloud SQL Admin
  - Storage Admin
  - Security Admin
  - Service Account Admin

### 3. Local Environment
```bash
# Install required tools
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Install kubectl
gcloud components install kubectl

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

## 🚀 Deployment Steps

### Step 1: Prepare Configuration Files

1. **Copy Terraform variables template**:
   ```bash
   cd terraform/
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your values:
   ```hcl
   project_id  = "your-gcp-project-id"
   db_password = "your-secure-database-password-min-8-chars"
   region      = "asia-southeast2"
   zone        = "asia-southeast2-a"
   environment = "dev"
   ```

### Step 2: Initialize and Deploy Infrastructure

1. **Initialize Terraform**:
   ```bash
   cd terraform/
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan -var-file="terraform.tfvars"
   ```

3. **Apply the infrastructure**:
   ```bash
   terraform apply -var-file="terraform.tfvars"
   ```
   
   This process takes approximately 15-20 minutes and creates:
   - VPC network and subnets
   - GKE cluster with node pool
   - Cloud SQL PostgreSQL instance
   - Redis instance
   - Cloud Storage bucket
   - Artifact Registry repository
   - IAM service accounts and roles
   - Static IP for load balancer

### Step 3: Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials medusa-dev-cluster \
    --zone asia-southeast2-a \
    --project YOUR_PROJECT_ID

# Verify connection
kubectl get nodes
```

### Step 4: Build and Push Docker Image

1. **Configure Docker for Artifact Registry**:
   ```bash
   gcloud auth configure-docker asia-southeast2-docker.pkg.dev
   ```

2. **Build Docker image**:
   ```bash
   # From the project root directory
   docker build -f Dockerfile.server \
     -t asia-southeast2-docker.pkg.dev/YOUR_PROJECT_ID/medusa-dev/medusa:latest .
   ```

3. **Push to Artifact Registry**:
   ```bash
   docker push asia-southeast2-docker.pkg.dev/YOUR_PROJECT_ID/medusa-dev/medusa:latest
   ```

### Step 5: Create Kubernetes Secrets

1. **Create database and Redis secrets**:
   ```bash
   # Database URL (replace with actual values from Terraform output)
   kubectl create secret generic medusa-secrets \
     --from-literal=database-url="postgresql://medusa:PASSWORD@POSTGRES_IP:5432/medusa" \
     --from-literal=redis-url="redis://REDIS_IP:6379" \
     --from-literal=jwt-secret="$(openssl rand -base64 32)" \
     --from-literal=cookie-secret="$(openssl rand -base64 32)" \
     --namespace=medusa-dev
   ```

2. **Create Docker registry secret**:
   ```bash
   kubectl create secret docker-registry gcr-secret \
     --docker-server=asia-southeast2-docker.pkg.dev \
     --docker-username=_json_key \
     --docker-password="$(cat path/to/service-account-key.json)" \
     --docker-email=your-email@example.com \
     --namespace=medusa-dev
   ```

### Step 6: Deploy Kubernetes Resources

1. **Update deployment image**:
   ```bash
   # Edit k8s/deployment.yaml and replace PROJECT_ID with your actual project ID
   sed -i 's/PROJECT_ID/your-actual-project-id/g' k8s/deployment.yaml
   sed -i 's/PROJECT_ID/your-actual-project-id/g' k8s/rbac.yaml
   ```

2. **Apply Kubernetes manifests**:
   ```bash
   kubectl apply -f k8s/namespace.yaml
   kubectl apply -f k8s/rbac.yaml
   kubectl apply -f k8s/configmap.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   ```

3. **Apply ingress (after updating domains)**:
   ```bash
   # Edit k8s/ingress.yaml and replace your-domain.com with actual domains
   kubectl apply -f k8s/ingress.yaml
   ```

### Step 7: Run Database Migrations

```bash
# Connect to a pod and run migrations
kubectl exec -it deployment/medusa-server -n medusa-dev -- \
  npm run typeorm migration:run

# Or if using yarn
kubectl exec -it deployment/medusa-server -n medusa-dev -- \
  yarn typeorm migration:run
```

## ⚙️ Post-Deployment Configuration

### 1. Verify Deployment

```bash
# Check pod status
kubectl get pods -n medusa-dev

# Check service endpoints
kubectl get services -n medusa-dev

# Check ingress status
kubectl get ingress -n medusa-dev

# View pod logs
kubectl logs -f deployment/medusa-server -n medusa-dev
```

### 2. Access the Application

- **API Endpoint**: Use the static IP or configured domain
- **Health Check**: `http://LOAD_BALANCER_IP/health`
- **Admin Panel**: Configure admin user via API or environment variables

### 3. Configure Domain Names (Optional)

1. Point your domain DNS to the static IP from Terraform output
2. Update ingress.yaml with your actual domain names
3. Apply the updated ingress configuration

### 4. SSL Certificate Setup

SSL certificates are automatically provisioned by Google-managed certificates when domains are properly configured.

## 📊 Monitoring and Maintenance

### 1. Set Up Monitoring

```bash
# Enable monitoring in the cluster (if not already enabled)
gcloud container clusters update medusa-dev-cluster \
    --enable-cloud-monitoring \
    --zone asia-southeast2-a
```

### 2. Log Aggregation

Logs are automatically collected by Google Cloud Logging. Access them via:
- Google Cloud Console → Logging
- `kubectl logs` commands
- Log-based metrics and alerts

### 3. Health Checks

The deployment includes:
- Kubernetes liveness probes (HTTP /health endpoint)
- Kubernetes readiness probes (HTTP /health endpoint)
- Load balancer health checks

### 4. Backup Verification

```bash
# Verify database backups
gcloud sql backups list --instance=medusa-dev-postgres

# Test backup restoration (in staging environment)
gcloud sql backups restore BACKUP_ID --restore-instance=medusa-staging-postgres
```

## 💰 Cost Optimization

### Development Environment Optimizations

1. **Preemptible Instances**: Using preemptible GKE nodes (70% cost reduction)
2. **Right-sizing**: 
   - db-f1-micro for PostgreSQL (lowest tier)
   - 1GB Redis instance
   - e2-medium nodes with autoscaling
3. **Regional Resources**: Using regional instead of global resources where possible
4. **Automated Cleanup**: Lifecycle policies for storage and backups

### Estimated Monthly Costs (Development)

- **GKE Cluster**: ~$50-70/month (2 preemptible e2-medium nodes)
- **Cloud SQL**: ~$15-25/month (db-f1-micro)
- **Redis**: ~$25-35/month (1GB basic tier)
- **Storage**: ~$2-5/month (depending on usage)
- **Load Balancer**: ~$20-25/month
- **Network**: ~$5-10/month

**Total Estimated**: $120-170/month for development environment

## 🔒 Security Considerations

### 1. Network Security
- Private GKE cluster with no public IP addresses on nodes
- VPC-native networking with private Google access
- Firewall rules restricting access to necessary ports only
- Cloud NAT for outbound internet access from private nodes

### 2. Data Security
- Database encryption at rest and in transit
- Redis AUTH disabled (VPC-level security)
- Secret Manager for sensitive configuration
- Workload Identity for secure GCP service access

### 3. Access Control
- Least privilege IAM roles
- Kubernetes RBAC for pod-level permissions
- Service account annotations for Workload Identity
- No persistent credentials in container images

### 4. SSL/TLS
- Google-managed SSL certificates for domains
- Force HTTPS redirect via ingress
- Backend communication over TLS

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Pod Startup Issues
```bash
# Check pod events
kubectl describe pod POD_NAME -n medusa-dev

# Check container logs
kubectl logs POD_NAME -c medusa-server -n medusa-dev

# Common issues:
# - Database connection: Verify database URL in secrets
# - Image pull: Check Artifact Registry permissions
# - Resource limits: Adjust CPU/memory in deployment.yaml
```

#### 2. Database Connection Problems
```bash
# Test database connectivity from pod
kubectl exec -it POD_NAME -n medusa-dev -- \
  psql postgresql://medusa:PASSWORD@DB_IP:5432/medusa

# Verify Cloud SQL private IP
gcloud sql instances describe medusa-dev-postgres
```

#### 3. Ingress/Load Balancer Issues
```bash
# Check ingress status
kubectl describe ingress medusa-ingress -n medusa-dev

# Verify backend health
kubectl get backendconfig -n medusa-dev

# Check GCP load balancer status in Console
```

#### 4. SSL Certificate Issues
```bash
# Check managed certificate status
kubectl describe managedcertificate medusa-ssl-cert -n medusa-dev

# Verify domain DNS configuration
nslookup your-domain.com
```

### Emergency Procedures

#### 1. Scale Down for Maintenance
```bash
kubectl scale deployment medusa-server --replicas=0 -n medusa-dev
```

#### 2. Database Backup and Restore
```bash
# Create on-demand backup
gcloud sql backups create --instance=medusa-dev-postgres

# Restore from backup
gcloud sql backups restore BACKUP_ID --restore-instance=medusa-dev-postgres
```

#### 3. Rolling Update
```bash
# Update deployment with new image
kubectl set image deployment/medusa-server \
  medusa-server=asia-southeast2-docker.pkg.dev/PROJECT_ID/medusa-dev/medusa:NEW_TAG \
  -n medusa-dev

# Monitor rollout
kubectl rollout status deployment/medusa-server -n medusa-dev
```

## 📈 Scaling for Production

When ready to move to production, consider:

1. **Multi-zone deployment** for high availability
2. **Horizontal Pod Autoscaler** based on CPU/memory metrics
3. **Regional persistent disks** for database
4. **Cloud SQL HA configuration** with read replicas
5. **Redis cluster mode** for cache high availability
6. **CDN integration** for static assets
7. **Enhanced monitoring** with alerting policies
8. **Disaster recovery** procedures and testing

## 📝 Additional Resources

- [Medusa Documentation](https://docs.medusajs.com)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)

---

**Note**: This deployment plan is optimized for development environments. For production deployments, additional considerations for high availability, security hardening, and performance optimization should be implemented.