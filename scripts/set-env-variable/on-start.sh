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
CURR_VERSION=$(cat /etc/os-release)
if [[ $CURR_VERSION == *$"http://aws.amazon.com/amazon-linux-ami/"* ]]; then
	sudo initctl restart jupyter-server --no-wait
else
	sudo systemctl --no-block restart jupyter-server.service
fi

#EOF