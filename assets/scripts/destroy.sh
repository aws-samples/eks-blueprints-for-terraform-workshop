#!/bin/bash

set -uo pipefail

$BASE_DIR/assets/scripts/destroy-applications.sh

$BASE_DIR/assets/scripts/destroy-spoke.sh default

$BASE_DIR/assets/scripts/destroy-hub.sh

$BASE_DIR/assets/scripts/destroy-git.sh

$BASE_DIR/assets/scripts/destroy-vpc.sh 




