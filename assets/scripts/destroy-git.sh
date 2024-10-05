#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

cd $WORKSHOP_DIR/terraform/common

terraform destroy  -auto-approve