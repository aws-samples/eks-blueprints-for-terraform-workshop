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
# Clone and initialize the gitops repositories
gitops_org_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-platform-repo --query SecretString --output text | jq -r .org)"
gitops_retail_store_app_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-retail-store-app-repo --query SecretString --output text | jq -r .url)"
gitops_retail_store_config_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-retail-store-config-repo --query SecretString --output text | jq -r .url)"
gitops_platform_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-platform-repo --query SecretString --output text | jq -r .url)"
gitops_guestbook_manifest_url="${gitops_org_url}/workshop-user/guestbook-manifest"
GIT_USER="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-platform-repo --query SecretString --output text | jq -r .username)"
GIT_PASS="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-platform-repo --query SecretString --output text | jq -r .password)"
# gitops_addons_url="$(aws secretsmanager   get-secret-value --secret-id ${PROJECT_CONTEXT_PREFIX}-addons --query SecretString --output text | jq -r .url)"

# if IDE_URL is set then setup
if [[ -n "${IDE_URL:-}" ]]; then
    echo "IDE_URL is set"
    GIT_CREDS="$HOME/.git-credentials"
    # Setup for HTTPs Gitea
    GITEA_URL=${IDE_URL}/gitea
cat > $GIT_CREDS << EOT
${GITEA_URL/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
EOT
    git config --global credential.helper 'store'
    git config --global init.defaultBranch main
else
    gitops_retail_store_app_url=${gitops_retail_store_app_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
    gitops_retail_store_config_url=${gitops_retail_store_config_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
    gitops_platform_url=${gitops_platform_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
    gitops_guestbook_manifest_url=${gitops_guestbook_manifest_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
fi

# Reset directory
rm -rf ${GITOPS_DIR}
mkdir -p ${GITOPS_DIR}

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


# populate guestbook-manfiest repository
git init ${GITOPS_DIR}/guestbook-manifest
git -C ${GITOPS_DIR}/guestbook-manifest remote add origin ${gitops_guestbook_manifest_url}
cp -r ${ROOTDIR}/gitops/guestbook-manifest/*  ${GITOPS_DIR}/guestbook-manifest/
git -C ${GITOPS_DIR}/guestbook-manifest add . || true
git -C ${GITOPS_DIR}/guestbook-manifest commit -m "initial commit" || true
git -C ${GITOPS_DIR}/guestbook-manifest push -u origin main -f || true

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

# # populate addons repository
# git init ${GITOPS_DIR}/addons
# git -C ${GITOPS_DIR}/addons remote add origin ${gitops_addons_url}
# cp -r ${ROOTDIR}/gitops/addons/* ${GITOPS_DIR}/addons/

# git -C ${GITOPS_DIR}/addons add . || true
# git -C ${GITOPS_DIR}/addons commit -m "initial commit" || true
# git -C ${GITOPS_DIR}/addons push -u origin main -f  || true
