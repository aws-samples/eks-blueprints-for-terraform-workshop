#!/bin/bash

set -uo pipefail

$BASE_DIR/hack/scripts/destroy-applications.sh

$BASE_DIR/hack/scripts/destroy-spoke.sh staging

$BASE_DIR/hack/scripts/destroy-hub.sh

$BASE_DIR/hack/scripts/destroy-git.sh

$BASE_DIR/hack/scripts/destroy-vpc.sh 




