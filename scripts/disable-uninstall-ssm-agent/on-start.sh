#!/bin/bash


# OVERVIEW
# This script disables and uninstalls the SSM agent which is present by default on Notebook Instances.
# NOTE: The SSM Agent will still be enabled for the short period between the Notebook Instance initiating and the Lifecycle Configuration script executing

ssm_status=$(status amazon-ssm-agent)

# Set -e after "status" so that the script doesn't fail if the SSM agent is already stopped
set -e

if [[ "$ssm_status" =~ "running" ]]; 
then 
    echo "Stopping SSM Agent.."
    stop amazon-ssm-agent
fi

echo "Uninstalling SSM Agent.."
yum erase amazon-ssm-agent --assumeyes