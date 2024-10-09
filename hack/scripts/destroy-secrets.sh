#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source the functions file using the script directory
if [ -f "$SCRIPT_DIR/functions.sh" ]; then
    . "$SCRIPT_DIR/functions.sh"
else
    echo "Error: functions.sh not found in $SCRIPT_DIR"
    exit 1
fi

ASK_DELETE=true
ACCEPT_DELETE=true
SECRET_NAMES=("eks-blueprints-workshop-gitops-workloads" "eks-blueprints-workshop-gitops-platform" "eks-blueprints-workshop-gitops-addons")


delete_secrets_manager_secrets