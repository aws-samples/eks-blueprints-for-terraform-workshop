#!/bin/bash

set -uo pipefail

$WORKSHOP_DIR/assets/scripts/destroy-applications.sh

$WORKSHOP_DIR/assets/scripts/destroy-spoke.sh default

$WORKSHOP_DIR/assets/scripts/destroy-hub.sh

$WORKSHOP_DIR/assets/scripts/destroy-git.sh

$WORKSHOP_DIR/assets/scripts/destroy-vpc.sh 




