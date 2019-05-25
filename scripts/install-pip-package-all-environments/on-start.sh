#!/bin/bash

set -e

# OVERVIEW
# This script installs a single pip package in all SageMaker conda environments, apart from the JupyterSystemEnv which is a 
# system environment reserved for Jupyter.

sudo -u ec2-user -i <<'EOF'

# PARAMETERS
PACKAGE=scipy

# Note that "base" is special environment name, include it there as well.
for env in base /home/ec2-user/anaconda3/envs/*; do
    source /home/ec2-user/anaconda3/bin/activate $(basename "$env")

    if [ $env = 'JupyterSystemEnv' ]; then
      continue
    fi

    pip install --upgrade "$PACKAGE"

    source /home/ec2-user/anaconda3/bin/deactivate
done

EOF