#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

terraform destroy  -auto-approve