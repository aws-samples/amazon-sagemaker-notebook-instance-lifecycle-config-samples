#!/bin/bash

set -e

# OVERVIEW
# This script mounts an EFS file system to the Notebook Instance at the ~/SageMaker/efs directory based off the DNS name.
# 
# Note that this script will fail if file system is not reachable from the Notebook Instance.
#   1. Ensure that the EFS file system DNS name is resolvable from the Notebook Instance
#       - One way to accomplish this is having the Notebook Instance and the EFS file system in the same subnet
#   2. Ensure the Mount Target Security Group provides inbound access from the Notebook Instance Security Group
#       Type - Protocol - Port - Source
#       NFS  - TCP      - 2049 - $NOTEBOOK_SECURITY_GROUP
#
# https://aws.amazon.com/blogs/machine-learning/mount-an-efs-file-system-to-an-amazon-sagemaker-notebook-with-lifecycle-configurations/

# PARAMETERS
EFS_DNS_NAME=fs-your-fs-id.efs.your-region.amazonaws.com

mkdir -p /home/ec2-user/SageMaker/efs
mount \
    --type nfs \
    --options nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
    $EFS_DNS_NAME:/ /home/ec2-user/SageMaker/efs \
    --verbose

chmod go+rw /home/ec2-user/SageMaker/efs