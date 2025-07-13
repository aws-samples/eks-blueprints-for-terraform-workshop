#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

echo "=== VPC Destroy Script ==="

# Check if we have AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "Error: AWS credentials not configured"
    exit 1
fi

# Get current region and account
AWS_REGION=$(aws configure get region || echo "us-east-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Destroying VPC in region: $AWS_REGION"
echo "Account ID: $ACCOUNT_ID"

# Check if we have a Terraform state bucket (from SSM parameter)
TFSTATE_BUCKET=""
if aws ssm get-parameter --name "eks-blueprints-workshop-tf-backend-bucket" > /dev/null 2>&1; then
    TFSTATE_BUCKET=$(aws ssm get-parameter --name "eks-blueprints-workshop-tf-backend-bucket" --query "Parameter.Value" --output text)
    echo "Using Terraform state bucket: $TFSTATE_BUCKET"
    
    # Create backend override file
    cat > $SCRIPTDIR/backend_override.tf << EOF
terraform {
  backend "s3" {
    bucket = "$TFSTATE_BUCKET"
    key    = "vpc/terraform.tfstate"
    region = "$AWS_REGION"
  }
}
EOF
else
    echo "Warning: No Terraform state bucket found. Using local state."
    # Remove backend configuration for local state
    rm -f $SCRIPTDIR/backend_override.tf
fi

# Initialize Terraform
echo "Initializing Terraform..."
terraform -chdir=$SCRIPTDIR init -upgrade

# Plan the destroy
echo "Planning VPC destruction..."
terraform -chdir=$SCRIPTDIR plan -destroy

# Destroy the deployment
echo "Destroying VPC..."
terraform -chdir=$SCRIPTDIR destroy -auto-approve

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "SUCCESS: VPC destruction completed successfully"
else
    echo "FAILED: VPC destruction failed"
    exit 1
fi
