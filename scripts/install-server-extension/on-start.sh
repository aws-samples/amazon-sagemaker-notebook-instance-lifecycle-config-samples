#!/bin/bash

set -e

# OVERVIEW
# This script installs a single jupyter notebook server extension package in SageMaker Notebook Instance

sudo -u ec2-user -i <<'EOF'

# PARAMETERS
PIP_PACKAGE_NAME=jupyterlab-git
EXTENSION_NAME=jupyterlab_git

source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv

pip install $PIP_PACKAGE_NAME
jupyter serverextension enable $EXTENSION_NAME --py --sys-prefix

source /home/ec2-user/anaconda3/bin/deactivate

EOF
