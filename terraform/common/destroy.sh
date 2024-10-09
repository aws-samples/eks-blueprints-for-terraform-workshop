#!/usr/bin/env bash

set -uo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

echo "Destroying AWS git and iam resources"
terraform -chdir=$SCRIPTDIR init --upgrade
TF_VAR_gitea_external_url=$GITEA_EXTERNAL_URL TF_VAR_gitea_password=$GITEA_PASSWORD terraform -chdir=$SCRIPTDIR destroy -auto-approve
echo TF_VAR_gitea_external_url=$GITEA_EXTERNAL_URL TF_VAR_gitea_password=$GITEA_PASSWORD terraform -chdir=$SCRIPTDIR destroy -auto-approve

# Delete parameter created in the bootstrap
aws ssm delete-parameter --name EksBlueprintGiteaExternalUrl || true

