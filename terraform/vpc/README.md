# VPC Module for EKS Blueprints Workshop

This module creates a pre-configured VPC for the EKS Blueprints workshop to reduce deployment time.

## What it creates

- VPC with public and private subnets across 3 availability zones
- Internet Gateway for public subnet access
- NAT Gateway for private subnet internet access (single NAT for cost optimization)
- Proper subnet tagging for EKS load balancer discovery
- Network ACLs, route tables, and security groups

## Quick Start

### Deploy VPC
```bash
cd vpc
./deploy.sh
```

### Destroy VPC
```bash
cd vpc
./destroy.sh
```

## Manual Deployment

If you prefer to run Terraform commands manually:

```bash
cd vpc

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the deployment
terraform apply

# View outputs
terraform output
```

## Configuration

The VPC can be customized by modifying variables in `variables.tf`:

- `environment_name`: Name prefix for resources (default: "eks-blueprints-workshop")
- `vpc_cidr`: CIDR block for the VPC (default: "10.0.0.0/16")

## Outputs

After deployment, the module outputs:

- `vpc_id`: The VPC ID for use in EKS cluster configuration
- `private_subnets`: List of private subnet IDs for EKS node groups
- `vpc_name`: The VPC name

## Integration with Workshop

This VPC module is designed to be deployed before the main workshop infrastructure to:

1. Pre-create networking resources (saves 5+ minutes)
2. Provide stable VPC/subnet IDs for EKS cluster deployment
3. Ensure proper network configuration for Kubernetes workloads

## State Management

The module automatically detects if a Terraform state bucket is available (from SSM parameter `eks-blueprints-workshop-tf-backend-bucket`) and uses it for remote state storage. If not available, it falls back to local state.
