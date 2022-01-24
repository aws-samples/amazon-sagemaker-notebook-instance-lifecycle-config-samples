#!/bin/bash

set -e


# OVERVIEW
# This script installs a single pip package in a single SageMaker conda environments.
export ENVIRONMENT=ds-homegate

sudo -u ec2-user -i <<EOF

# PARAMETERS
echo Preparing $ENVIRONMENT
conda create --yes -n $ENVIRONMENT pip ipykernel watchtower urllib3[secure] requests python=3.7.12
conda activate ${ENVIRONMENT}

EOF

# OVERVIEW
# This script stops a SageMaker notebook once it's idle for more than 1 hour (default time)
# You can change the idle time for stop using the environment variable below.
# If you want the notebook the stop only if no browsers are open, remove the --ignore-connections flag
#
# Note that this script will fail if either condition is not met
#   1. Ensure the Notebook Instance has internet connectivity to fetch the example config
#   2. Ensure the Notebook Instance execution role permissions to SageMaker:StopNotebookInstance to stop the notebook 
#       and SageMaker:DescribeNotebookInstance to describe the notebook.
#

# PARAMETERS
IDLE_TIME=3600
PATH_TO_SCRIPT=/home/ec2-user/autostop.py
CONDA_ENV=/home/ec2-user/anaconda3/envs/${ENVIRONMENT}

echo "Prepared environment ${CONDA_ENV}"

echo "Fetching the autostop script"
wget https://raw.githubusercontent.com/homegate-engineering/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/auto-stop-idle/autostop.py -O ${PATH_TO_SCRIPT}

echo "Starting the SageMaker autostop script in cron"

(crontab -l 2>/dev/null; echo "*/5 * * * * ${CONDA_ENV}/bin/python ${PATH_TO_SCRIPT} --time $IDLE_TIME --ignore-connections") | crontab -

crontab -l
