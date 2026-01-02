#!/usr/bin/env bash

set -euo pipefail
set -x

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPTDIR
ROOTDIR=$SCRIPTDIR
[[ -n "${DEBUG:-}" ]] && set -x

GITOPS_DIR=${GITOPS_DIR:-$SCRIPTDIR/environment/gitops-repos}
echo $GITOPS_DIR

PROJECT_CONTEXT_PREFIX=${PROJECT_CONTEXT_PREFIX:-argocd-workshop}

# Configure Git for CodeCommit
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
git config --global init.defaultBranch main

# CodeCommit repository URLs
gitops_retail_store_app_url="https://git-codecommit.${AWS_REGION:-us-west-2}.amazonaws.com/v1/repos/retail-store-app"
gitops_retail_store_config_url="https://git-codecommit.${AWS_REGION:-us-west-2}.amazonaws.com/v1/repos/retail-store-config"
gitops_platform_url="https://git-codecommit.${AWS_REGION:-us-west-2}.amazonaws.com/v1/repos/platform"


# populate retail-store-app repository
git init ${GITOPS_DIR}/retail-store-app
git -C ${GITOPS_DIR}/retail-store-app remote add origin ${gitops_retail_store_app_url}
cp -r ${ROOTDIR}/gitops/retail-store-app/* ${GITOPS_DIR}/retail-store-app
git -C ${GITOPS_DIR}/retail-store-app add . || true
git -C ${GITOPS_DIR}/retail-store-app commit -m  "initial commit" --allow-empty  || true
git -C ${GITOPS_DIR}/retail-store-app push -u origin main -f  || true

# populate retail-store-config repository
git init ${GITOPS_DIR}/retail-store-config
git -C ${GITOPS_DIR}/retail-store-config remote add origin ${gitops_retail_store_config_url}
cp -r ${ROOTDIR}/gitops/retail-store-config/* ${GITOPS_DIR}/retail-store-config
git -C ${GITOPS_DIR}/retail-store-config add . || true
git -C ${GITOPS_DIR}/retail-store-config commit -m  "initial commit" --allow-empty  || true
git -C ${GITOPS_DIR}/retail-store-config push -u origin main -f  || true

# populate platform repository
git init ${GITOPS_DIR}/platform
git -C ${GITOPS_DIR}/platform remote add origin ${gitops_platform_url}
cp -r ${ROOTDIR}/gitops/platform/*  ${GITOPS_DIR}/platform/
git -C ${GITOPS_DIR}/platform add . || true
git -C ${GITOPS_DIR}/platform commit -m "initial commit" || true
git -C ${GITOPS_DIR}/platform push -u origin main -f || true

# Push existing Helm charts to ECR
echo "Pushing Helm charts to ECR..."
cd ${ROOTDIR}

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | helm registry login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Push all charts to ECR
# Process platform charts
for chart in gitops/helm/platform/*.tgz; do
  if [ -f "$chart" ]; then
    # Extract chart name from filename (remove path, .tgz extension, and version)
    chart_name=$(basename "$chart" .tgz | sed 's/-[0-9]\+\.[0-9]\+\.[0-9]\+$//')
    repo_name="platform/$chart_name"
    
    echo "Processing platform chart: $chart_name -> Repository: $repo_name"
    
    # Create ECR repository if it doesn't exist
    echo "Creating ECR repository for $repo_name..."
    aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION" 2>/dev/null || echo "Repository $repo_name already exists or creation failed"
    
    echo "Pushing $chart to ECR..."
    helm push "$chart" oci://$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/platform
  fi
done

# Process retail-store charts
for chart in gitops/helm/retail-store/*.tgz; do
  if [ -f "$chart" ]; then
    # Extract chart name from filename (remove path, .tgz extension, and version)
    chart_name=$(basename "$chart" .tgz | sed 's/-[0-9]\+\.[0-9]\+\.[0-9]\+$//')
    repo_name="retail-store/$chart_name"
    
    echo "Processing retail-store chart: $chart_name -> Repository: $repo_name"
    
    # Create ECR repository if it doesn't exist
    echo "Creating ECR repository for $repo_name..."
    aws ecr create-repository --repository-name "$repo_name" --region "$AWS_REGION" 2>/dev/null || echo "Repository $repo_name already exists or creation failed"
    
    echo "Pushing $chart to ECR..."
    helm push "$chart" oci://$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/retail-store
  fi
done

echo "All Helm charts pushed to ECR successfully!"
