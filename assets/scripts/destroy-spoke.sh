#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x


# Check if a parameter is provided
if [ -z "$1" ]; then
    echo "Error: No workspace provided."
    echo "Usage: $0 <parameter>"
    exit 1
fi

WORKSPACE=$1

cd ~/environment/spoke/

terraform workspace select $WORKSPACE


terraform destroy -target="module.gitops_bridge_bootstrap" -auto-approve
terraform destroy -target="module.eks_blueprints_addons" -auto-approve

#Remove EKS cluster
terraform destroy -target="module.eks" -auto-approve

# clean everything else
terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "Success: EKS Spoke $WORKSPACE deleted successfully."
else
    echo "Error: Failed to delete EKS Spoke $WORKSPACE, you may need to do some manuals cleanups"
fi

