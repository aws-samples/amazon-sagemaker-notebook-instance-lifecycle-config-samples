#!/bin/bash

set -e

# OVERVIEW
# This script logs the history of a notebook server to S3 once an hour/
#
# Note that this script will fail if either condition is not met
#   1. Ensure the Notebook Instance has internet connectivity to fetch the example config
#   2. Ensure the Notebook Instance execution role permissions to write a file to the Sagemaker default bucket

# DEPENDENCIES
pip install sagemaker

# PARAMETERS
echo "Fetching the log history script"
wget https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/notebook-history-s3/on-start.sh
echo "Starting the SageMaker logging script in cron"

(crontab -l 2>/dev/null; echo "0 * * * * /usr/bin/python3 $PWD/notebook_history_s3.py") | crontab -
