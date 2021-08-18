#!/bin/bash
set -e

# OVERVIEW
# This script downloads a snapshot specified by tags (ebs-backup-bucket and backup-snapshot)on the notebook instance into /home/ec2-user/SageMaker/. 
# The snapshot can be created from an existing instace using https://github.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/tree/master/scripts/migrate-ebs-data-backup/on-start.sh.
# 
# Note that the execution is done with nohup to bypass the startup timeout set by SageMaker Notebook instance. Depending on the size of the source /home/ec2-user/SageMaker/, it may take more than 5 minutes. You would see a text file SYNC_COMPLETE created in /home/ec2-user/SageMaker/ to denote the completion. You need s3:GetObject, s3:PutObject, and s3:ListBucket for the S3 bucket in the execution role to perform aws s3 sync.
# 
# Note if your notebook instance is in VPC mode without a direct internet access, please create a S3 VPC Gateway endpoint (https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html) and a SageMaker API VPC interface endpoint (https://docs.aws.amazon.com/sagemaker/latest/dg/interface-vpc-endpoint.html).
#
# See detail instruction in https://aws.amazon.com/blogs/machine-learning/migrate-your-work-to-amazon-sagemaker-notebook-instance-with-amazon-linux-2/

cat << "EOF" > /home/ec2-user/sync.sh
# When creating a new AL2 notebook instance, sync from a snapshot in S3 bucket to /home/ec2-user/SageMaker/
NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
NOTEBOOK_NAME=$(jq '.ResourceName' /opt/ml/metadata/resource-metadata.json --raw-output)
VAR_BACKUP_SOURCE=ebs-backup-bucket
BUCKET=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN  | jq -r --arg VAR_BACKUP_SOURCE "$VAR_BACKUP_SOURCE" .'Tags[] | select(.Key == $VAR_BACKUP_SOURCE).Value' --raw-output)
VAR_SNAPSHOT=backup-snapshot
SNAPSHOT=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN  | jq -r --arg VAR_SNAPSHOT "$VAR_SNAPSHOT" .'Tags[] | select(.Key == $VAR_SNAPSHOT).Value' --raw-output)

# check if SNAPSHOT exists, if not, proceed without sync
echo "Checking if s3://${BUCKET}/${SNAPSHOT} exists..."
aws s3 ls s3://${BUCKET}/${SNAPSHOT} || (echo "Snapshot s3://${BUCKET}/${SNAPSHOT} does not exist. Proceed without the sync."; exit 0)
echo "Sync-ing s3://${BUCKET}/${SNAPSHOT}/ to /home/ec2-user/SageMaker/"
aws s3 sync s3://${BUCKET}/${SNAPSHOT}/ /home/ec2-user/SageMaker/ 
exitcode=$?
echo $exitcode
if [ $exitcode -eq 0 ] || [ $exitcode -eq 2 ]
then
    TIMESTAMP=`date +%F-%H-%M-%S`
    echo "Completed at $TIMESTAMP" > /home/ec2-user/SageMaker/SYNC_COMPLETE
fi
EOF

chmod +x /home/ec2-user/sync.sh
chown ec2-user:ec2-user /home/ec2-user/sync.sh

# nohup to bypass the notebook instance timeout at start
sudo -u ec2-user nohup /home/ec2-user/sync.sh >>  /home/ec2-user/nohup.out 2>&1 &
 
