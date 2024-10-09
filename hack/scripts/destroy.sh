#!/bin/bash

set -uo pipefail

$BASE_DIR/hack/scripts/destroy-applications.sh

$BASE_DIR/hack/scripts/destroy-spoke.sh default

$BASE_DIR/hack/scripts/destroy-hub.sh

$BASE_DIR/hack/scripts/destroy-git.sh

$BASE_DIR/hack/scripts/destroy-vpc.sh 




