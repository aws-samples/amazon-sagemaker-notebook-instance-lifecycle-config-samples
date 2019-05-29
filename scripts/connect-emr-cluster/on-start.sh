#!/bin/bash

set -e

# OVERVIEW
# This script connects an EMR cluster to the Notebook Instance using SparkMagic.
# 
# Note that this script will fail if the EMR cluster's master node IP address not reachable
#   1. Ensure that the EMR master node IP is resolvable from the Notebook Instance.
#       - One way to accomplish this is having the Notebook Instance and the EMR cluster in the same subnet
#   2. Ensure the EMR master node Security Groups provides inbound access from the Notebook Instance Security Group
#       Type        - Protocol - Port - Source
#       Custom TCP  - TCP      - 8998 - $NOTEBOOK_SECURITY_GROUP
#   3. Ensure the Notebook Instance has internet connectivity to fetch the SparkMagic example config  
#
# https://aws.amazon.com/blogs/machine-learning/build-amazon-sagemaker-notebooks-backed-by-spark-in-amazon-emr/

# PARAMETERS
EMR_MASTER_IP=your.emr.master.ip

cd /home/ec2-user/.sparkmagic

echo "Fetching SparkMagic example config from GitHub.."
wget https://raw.githubusercontent.com/jupyter-incubator/sparkmagic/master/sparkmagic/example_config.json

echo "Replacing EMR master node IP in SparkMagic config.."
sed -i -- "s/localhost/$EMR_MASTER_IP/g" example_config.json
mv example_config.json config.json

echo "Sending a sample request to Livy.."
curl "$EMR_MASTER_IP:8998/sessions"