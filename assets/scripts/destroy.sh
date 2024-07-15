#!/bin/bash

set -uo pipefail

$SOURCE_DIR/assets/scripts/destroy-applications.sh

$SOURCE_DIR/assets/scripts/destroy-spoke.sh staging

$SOURCE_DIR/assets/scripts/destroy-hub.sh

$SOURCE_DIR/assets/scripts/destroy-git.sh

$SOURCE_DIR/assets/scripts/destroy-vpc.sh 




