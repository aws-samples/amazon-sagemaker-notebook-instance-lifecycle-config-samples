#!/bin/bash

set -e

# OVERVIEW
# This script upgrades the SageMaker Python SDK to v2 in all Python 3 environments.
#
# For more details, see https://sagemaker.readthedocs.io/en/stable/v2.html

sudo -u ec2-user -i <<'EOF'

for env in base /home/ec2-user/anaconda3/envs/*; do
    source /home/ec2-user/anaconda3/bin/activate $(basename "$env")

    py_version=$(python -c 'import sys; print(sys.version_info[0])')

    if [ $env == 'JupyterSystemEnv' ] || [ $py_version == 2 ]; then
        continue
    fi

    pip install --upgrade 'sagemaker>2'

    source /home/ec2-user/anaconda3/bin/deactivate
done

EOF
