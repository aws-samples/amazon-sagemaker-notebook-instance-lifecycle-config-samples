#!/bin/bash

set -e

# OVERVIEW
# This script publishes the system-level metrics from the Notebook instance to Cloudwatch.
#
# Note that this script will fail if either condition is not met
#   1. Ensure the Notebook Instance has internet connectivity to fetch the example config
#   2. Ensure the Notebook Instance execution role permissions to cloudwatch:PutMetricData to publish the system-level metrics
#
# https://aws.amazon.com/cloudwatch/pricing/

# PARAMETERS
NOTEBOOK_INSTANCE_NAME=$(jq '.ResourceName' \
                      /opt/ml/metadata/resource-metadata.json --raw-output)

echo "Fetching the CloudWatch agent configuration file."
wget https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/publish-instance-metrics/amazon-cloudwatch-agent.json

sed -i -- "s/MyNotebookInstance/$NOTEBOOK_INSTANCE_NAME/g" amazon-cloudwatch-agent.json

echo "Starting the CloudWatch agent on the Notebook Instance."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a \
    append-config -m ec2 -c file://$(pwd)/amazon-cloudwatch-agent.json

CURR_VERSION=$(cat /etc/os-release)
if [[ $CURR_VERSION == *$"http://aws.amazon.com/amazon-linux-ami/"* ]]; then
    restart restart-cloudwatch-agent
else
    systemctl restart amazon-cloudwatch-agent.service
fi

rm amazon-cloudwatch-agent.json
