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
