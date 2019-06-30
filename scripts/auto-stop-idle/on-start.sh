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
IDLE_TIME=3600

echo "Fetching the autostop script"
wget https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/auto-stop-idle/autostop.py

echo "Starting the SageMaker autostop script in cron"

(crontab -l 2>/dev/null; echo "5 * * * * /usr/bin/python $PWD/autostop.py --time $IDLE_TIME") | crontab -