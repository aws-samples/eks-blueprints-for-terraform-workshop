#!/bin/bash

set -uo pipefail

[[ -n "${DEBUG:-}" ]] && set -x

cd ~/environment/codecommit/


terraform destroy  -auto-approve