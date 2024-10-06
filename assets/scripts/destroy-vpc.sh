#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source the functions file using the script directory
if [ -f "$SCRIPT_DIR/functions.sh" ]; then
    . "$SCRIPT_DIR/functions.sh"
else
    echo "Error: functions.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Default values
ASK_DELETE=true
ACCEPT_DELETE=true

VPC_NAMES=("eks-blueprints-workshop")

cd ~/environment/vpc/







#cleanup_vpc_resources
delete_vpc_endpoints

# # clean everything else
terraform destroy -auto-approve || true

#Do it 2 tims to be sure to delete everything
#cleanup_vpc_resources
delete_vpcs


terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "Success: VPC $VPCID deleted successfully."
else
    echo "Error: Failed to delete VPC $VPCID, you may need to do some manuals cleanups"
fi

