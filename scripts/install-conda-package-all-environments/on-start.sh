#!/bin/bash

set -e

# OVERVIEW
# This script installs a single conda package in all SageMaker conda environments, apart from the JupyterSystemEnv which is a 
# system environment reserved for Jupyter.

# NOTE: if the total runtime of this script exceeds 5 minutes, the Notebook Instance will fail to start up.  If you would
# like to run this script in the background, then replace "sudo" with "nohup sudo -b".  This will allow the
# Notebook Instance to start up while the installation happens in the background.

sudo -u ec2-user -i <<EOF

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
