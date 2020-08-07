#!/bin/bash

set -e

# OVERVIEW
# This script upgrades the SageMaker Python SDK to v2 in all environments.
#
# For more details, see https://sagemaker.readthedocs.io/en/stable/v2.html

sudo -u ec2-user -i <<'EOF'

for env in base /home/ec2-user/anaconda3/envs/*; do
    source /home/ec2-user/anaconda3/bin/activate $(basename "$env")

    if [ $env = 'JupyterSystemEnv' ]; then
        continue
    fi

    pip install --upgrade sagemaker>2

    source /home/ec2-user/anaconda3/bin/deactivate
done

EOF
