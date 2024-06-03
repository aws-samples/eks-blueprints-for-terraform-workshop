#!/bin/bash

set -uo pipefail

~/environment/wgit/assets/scripts/destroy-applications.sh staging

~/environment/wgit/assets/scripts/destroy-spoke.sh staging

~/environment/wgit/assets/scripts/destroy-hub.sh staging


~/environment/wgit/assets/scripts/destroy-vpc.sh staging





