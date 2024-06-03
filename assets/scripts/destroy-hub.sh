#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

cd ~/environment/hub/


terraform destroy -target="module.gitops_bridge_bootstrap" -auto-approve
terraform destroy -target="module.eks_blueprints_addons" -auto-approve

#Remove EKS cluster
terraform destroy -target="module.eks" -auto-approve

cleanup_vpc_resources $WORKSPACE

# # clean everything else
terraform destroy -auto-approve || true

#Do it 2 tims to be sure to delete everything
cleanup_vpc_resources $WORKSPACE

terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo "Success: VPC $VPCID deleted successfully."
else
    echo "Error: Failed to delete VPC $VPCID, you may need to do some manuals cleanups"
fi

