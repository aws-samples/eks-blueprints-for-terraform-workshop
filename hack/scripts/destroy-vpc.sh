#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/functions.sh"


VPC_NAMES=("eks-blueprints-workshop")



parse_arguments "$@"

#cleanup_vpc_resources
delete_vpc_endpoints

# # clean everything else
cd ~/environment/vpc/
terraform destroy -auto-approve || true

#Do it 2 tims to be sure to delete everything
#cleanup_vpc_resources
delete_vpcs


terraform destroy -auto-approve
