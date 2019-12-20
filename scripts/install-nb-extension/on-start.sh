#!/bin/bash

set -e

# OVERVIEW
# This script installs a single jupyter notebook extension package in SageMaker Notebook Instance
# For more details of the example extension, see https://github.com/jupyter-widgets/ipywidgets

sudo -u ec2-user -i <<EOF

# PARAMETERS
PIP_PACKAGE_NAME=ipywidgets
EXTENSION_NAME=widgetsnbextension

source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv

pip install $PIP_PACKAGE_NAME
jupyter nbextension enable $EXTENSION_NAME --py --sys-prefix

source /home/ec2-user/anaconda3/bin/deactivate

EOF
