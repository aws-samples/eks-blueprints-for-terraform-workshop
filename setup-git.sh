#!/usr/bin/env bash

set -euo pipefail
set -x

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPTDIR
ROOTDIR=$SCRIPTDIR
[[ -n "${DEBUG:-}" ]] && set -x

GITOPS_DIR=${GITOPS_DIR:-$SCRIPTDIR/environment/gitops-repos}
echo $GITOPS_DIR

PROJECT_CONTECXT_PREFIX=${PROJECT_CONTECXT_PREFIX:-eks-blueprints-workshop-gitops}
# Clone and initialize the gitops repositories
gitops_workload_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTECXT_PREFIX}-workloads --query SecretString --output text | jq -r .url)"
GIT_USER="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTECXT_PREFIX}-workloads --query SecretString --output text | jq -r .username)"
GIT_PASS="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTECXT_PREFIX}-workloads --query SecretString --output text | jq -r .password)"
gitops_platform_url="$(aws secretsmanager get-secret-value --secret-id ${PROJECT_CONTECXT_PREFIX}-platform --query SecretString --output text | jq -r .url)"
gitops_addons_url="$(aws secretsmanager   get-secret-value --secret-id ${PROJECT_CONTECXT_PREFIX}-addons --query SecretString --output text | jq -r .url)"

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
    gitops_workload_url=${gitops_workload_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
    gitops_platform_url=${gitops_platform_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
    gitops_addons_url=${gitops_addons_url/#https:\/\//https:\/\/"$GIT_USER":"$GIT_PASS"@}
fi

# Reset directory
rm -rf ${GITOPS_DIR}
mkdir -p ${GITOPS_DIR}

# populate workload repository
git init ${GITOPS_DIR}/workload
git -C ${GITOPS_DIR}/workload remote add origin ${gitops_workload_url}
###workload will be populated in workshop chpaters
#cp -r ${ROOTDIR}/gitops/workload/*  ${GITOPS_DIR}/workload

git -C ${GITOPS_DIR}/workload add . || true
git -C ${GITOPS_DIR}/workload commit -m "initial commit" || true
git -C ${GITOPS_DIR}/workload push -u origin main -f  || true

# populate platform repository
git init ${GITOPS_DIR}/platform
git -C ${GITOPS_DIR}/platform remote add origin ${gitops_platform_url}
cp -r ${ROOTDIR}/gitops/platform/*  ${GITOPS_DIR}/platform/

git -C ${GITOPS_DIR}/platform add . || true
git -C ${GITOPS_DIR}/platform commit -m "initial commit" || true
git -C ${GITOPS_DIR}/platform push -u origin main -f || true

# populate addons repository
git init ${GITOPS_DIR}/addons
git -C ${GITOPS_DIR}/addons remote add origin ${gitops_addons_url}
cp -r ${ROOTDIR}/gitops/addons/* ${GITOPS_DIR}/addons/

git -C ${GITOPS_DIR}/addons add . || true
git -C ${GITOPS_DIR}/addons commit -m "initial commit" || true
git -C ${GITOPS_DIR}/addons push -u origin main -f  || true
