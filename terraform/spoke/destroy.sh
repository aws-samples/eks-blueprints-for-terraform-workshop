#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/../..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

echo "Destroying Spoke EKS cluster resources"

# Initialize Terraform
terraform -chdir=$SCRIPTDIR init --upgrade

terraform -chdir=$SCRIPTDIR workspace select ${WORKSPACE:-dev}

terraform -chdir=$SCRIPTDIR destroy -auto-approve

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  echo "SUCCESS: Terraform destroy of Spoke EKS cluster module completed successfully"
else
  echo "FAILED: Terraform destroy of Spoke EKS cluster module failed"
  exit 1
fi
