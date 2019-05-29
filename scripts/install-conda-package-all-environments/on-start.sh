#!/bin/bash

set -e

# OVERVIEW
# This script installs a single conda package in all SageMaker conda environments, apart from the JupyterSystemEnv which is a 
# system environment reserved for Jupyter.
# Note this may timeout if the package installations in all environments take longer than 5 mins, consider using "nohup" to run this 
# as a background process in that case.

sudo -u ec2-user -i <<'EOF'

# PARAMETERS
PACKAGE=scipy


# Note that "base" is special environment name, include it there as well.
conda install "$PACKAGE" --name base --yes

for env in /home/ec2-user/anaconda3/envs/*; do
    env_name=$(basename "$env")
    if [ $env_name = 'JupyterSystemEnv' ]; then
      continue
    fi

    conda install "$PACKAGE" --name "$env_name" --yes
done

EOF