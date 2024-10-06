#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

cd $BASE_DIR/terraform/common

terraform destroy  -auto-approve