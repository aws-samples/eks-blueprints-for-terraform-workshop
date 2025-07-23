#!/usr/bin/env bash

set -uo pipefail

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOTDIR="$(cd ${SCRIPTDIR}/..; pwd )"
[[ -n "${DEBUG:-}" ]] && set -x

echo "Destroying AWS VPC resources"
terraform -chdir=$SCRIPTDIR init --upgrade

echo "Proceeding with VPC destruction..."
terraform -chdir=$SCRIPTDIR destroy -auto-approve
