#!/bin/bash

set -e

# OVERVIEW
# This script installs one or more pip packages in all SageMaker conda environments running Python v3, apart from the
# JupyterSystemEnv which is a system environment reserved for Jupyter.
#
# Note this may timeout if the package installations in all environments take longer than 5 mins, consider using
# "nohup" to run this as a background process in that case.

sudo -u ec2-user -i <<'EOF'
# PARAMETERS
PACKAGES='sagemaker-experiments smdebug'

# Note that "base" is special environment name that you could also consider omitting, but we include it here
for env in base /home/ec2-user/anaconda3/envs/*; do
    source /home/ec2-user/anaconda3/bin/activate $(basename "$env")
    if [ $env = 'JupyterSystemEnv' ]; then
        echo "Skipping JupyterSystemEnv"
        continue
    elif ! [[ "$(python -V 2>&1)" =~ Python\ 3 ]]; then
        echo "Skipping Python 2 environment $env"
        continue
    fi
    # `eval` here allows $PACKAGES to be multiple rather than one only:
    eval pip install --upgrade "$PACKAGES"
    source /home/ec2-user/anaconda3/bin/deactivate
done
EOF
