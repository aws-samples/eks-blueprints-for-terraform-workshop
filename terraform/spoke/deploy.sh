#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/../..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

# Initialize Terraform
terraform -chdir=$SCRIPTDIR init --upgrade

terraform workspace new staging

echo "Applying Spoke EKS cluster resources"

terraform -chdir=$SCRIPTDIR apply -auto-approve

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  echo "SUCCESS: Terraform apply of Spoke EKS cluster module completed successfully"
else
  echo "FAILED: Terraform apply of Spoke EKS cluster module failed"
  exit 1
fi
