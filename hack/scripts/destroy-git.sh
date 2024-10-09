#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

cd $BASE_DIR/terraform/common

TF_VAR_gitea_external_url=$GITEA_EXTERNAL_URL TF_VAR_gitea_password=$GITEA_PASSWORD terraform destroy  -auto-approve