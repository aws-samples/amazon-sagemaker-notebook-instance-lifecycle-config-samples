#!/bin/bash

set -e

# OVERVIEW
# This script installs a single pip package in a single SageMaker conda environments.

sudo -u ec2-user -i <<'EOF'

# PARAMETERS
PACKAGE=scipy
ENVIRONMENT=python3

source /home/ec2-user/anaconda3/bin/activate "$ENVIRONMENT"

pip install --upgrade "$PACKAGE"

source /home/ec2-user/anaconda3/bin/deactivate

EOF
