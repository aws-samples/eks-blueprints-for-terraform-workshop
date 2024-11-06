#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/functions.sh"


CLUSTERS=("spoke-staging" "hub-cluster")

parse_arguments "$@"
delete_eks_clusters