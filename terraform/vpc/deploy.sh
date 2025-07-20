#!/usr/bin/env bash

set -euo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/../..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

# Initialize Terraform
terraform -chdir=$SCRIPTDIR init --upgrade

echo "Applying VPC resources"

terraform -chdir=$SCRIPTDIR apply -auto-approve

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
  echo "SUCCESS: Terraform apply of VPC module completed successfully"
else
  echo "FAILED: Terraform apply of VPC module failed"
  exit 1
fi
