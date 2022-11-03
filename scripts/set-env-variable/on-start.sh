#!/bin/bash

set -e

# OVERVIEW
# This script gets value from Notebook Instance's tag and sets it as environment
# variable for all process including Jupyter in SageMaker Notebook Instance
# Note that this script will fail this condition is not met
#   1. Ensure the Notebook Instance execution role has permission of SageMaker:ListTags
#

#sudo -u ec2-user -i <<'EOF'

# PARAMETERS
YOUR_ENV_VARIABLE_NAME=<ENV_VAR_NAME>

NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
TAG=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN  | jq -r --arg YOUR_ENV_VARIABLE_NAME "$YOUR_ENV_VARIABLE_NAME" .'Tags[] | select(.Key == $YOUR_ENV_VARIABLE_NAME).Value' --raw-output)
touch /etc/profile.d/jupyter-env.sh
echo "export $YOUR_ENV_VARIABLE_NAME=$TAG" >> /etc/profile.d/jupyter-env.sh

# restart command is dependent on current running Amazon Linux and JupyterLab
CURR_VERSION_AL=$(cat /etc/system-release)
CURR_VERSION_JS=$(jupyter --version)

if [[ $CURR_VERSION_JS == *$"jupyter_core     : 4.9.1"* ]] && [[ $CURR_VERSION_AL == *$" release 2018"* ]]; then
	sudo initctl restart jupyter-server --no-wait
else
	sudo systemctl --no-block restart jupyter-server.service || true
fi

#EOF