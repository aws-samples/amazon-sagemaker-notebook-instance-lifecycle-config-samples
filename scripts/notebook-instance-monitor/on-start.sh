#!/bin/bash

set -ex

# OVERVIEW
# Change the conditions in the python script to monitpr and stop notebook instances with this lifecycle config script

echo "Fetching the scripts"
wget https://raw.githubusercontent.com/w601sxs/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/notebook-instance-monitor/autostop.py
wget https://raw.githubusercontent.com/w601sxs/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/notebook-instance-monitor/amazon-cloudwatch-agent.json


echo "Detecting Python install with boto3 install"

# Find which install has boto3 and use that to run the cron command. So will use default when available
# Redirect stderr as it is unneeded
if /usr/bin/python3 -c "import boto3" 2>/dev/null; then
    # Standard installation in any notebook instance should find both python3 and pip-3
    PYTHON_DIR='/usr/bin/python3'
    /usr/bin/pip-3 install gputil psutil --user
else
    # If no boto3 just quit because the script won't work
    echo "No boto3 found in Python or Python3. Exiting..."
    exit 1
fi

echo "Found boto3 at $PYTHON_DIR"


echo "Starting the SageMaker autostop script in cron"

(crontab -l 2>/dev/null; echo "*/30 * * * * $PYTHON_DIR $PWD/notebookapi.py >> /var/log/jupyter.log") | crontab -


echo "Also turning on cloudwatch metrics through the CW agent"

NOTEBOOK_INSTANCE_NAME=$(jq '.ResourceName' \
                      /opt/ml/metadata/resource-metadata.json --raw-output)


sed -i -- "s/MyNotebookInstance/$NOTEBOOK_INSTANCE_NAME/g" amazon-cloudwatch-agent.json

echo "Starting the CloudWatch agent on the Notebook Instance."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a \
    append-config -m ec2 -c file://$(pwd)/amazon-cloudwatch-agent.json

restart restart-cloudwatch-agent || true 
systemctl restart amazon-cloudwatch-agent.service || true

rm amazon-cloudwatch-agent.json