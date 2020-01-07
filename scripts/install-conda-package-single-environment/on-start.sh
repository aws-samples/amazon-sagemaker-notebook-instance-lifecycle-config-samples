#!/bin/bash

set -e

# OVERVIEW
# This script installs a single conda package in a single SageMaker conda environments.

sudo -u ec2-user -i <<'EOF'

# PARAMETERS
PACKAGE=scipy
ENVIRONMENT=python3

conda install "$PACKAGE" --name "$ENVIRONMENT" --yes

EOF
