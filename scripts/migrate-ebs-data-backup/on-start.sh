#!/bin/bash
set -e

# OVERVIEW
# This script creates a snapshot of EBS volume /home/ec2-user/SageMaker/ to a S3 bucket specified by tag on the notebook instance (ebs-backup-bucket). 
#
# The snapshot can be download into a new instance using https://github.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/tree/master/scripts/migrate-ebs-data-sync/on-create.sh.
# 
# Note that the execution is done with nohup to bypass the startup timeout set by SageMaker Notebook instance. Depending on the size of the source /home/ec2-user/SageMaker/, it may take more than 5 minutes. You would see a text file BACKUP_COMPLETE created in /home/ec2-user/SageMaker/ and in the S3 bucket to denote the completion. You need s3:CreateBucket, s3:GetObject, s3:PutObject, and s3:ListBucket in the execution role to perform aws s3 sync.
#
# Note if your notebook instance is in VPC mode without a direct internet access, please create a S3 VPC Gateway endpoint (https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html) and a SageMaker API VPC interface endpoint (https://docs.aws.amazon.com/sagemaker/latest/dg/interface-vpc-endpoint.html).
#
# See detail instruction in https://aws.amazon.com/blogs/machine-learning/xxxxx

cat << "EOF" > /home/ec2-user/backup.sh
#!/bin/bash
NOTEBOOK_ARN=$(jq '.ResourceArn' /opt/ml/metadata/resource-metadata.json --raw-output)
NOTEBOOK_NAME=$(jq '.ResourceName' /opt/ml/metadata/resource-metadata.json --raw-output)
BACKUP_DESTINATION=ebs-backup-bucket
BUCKET=$(aws sagemaker list-tags --resource-arn $NOTEBOOK_ARN  | jq -r --arg BACKUP_DESTINATION "$BACKUP_DESTINATION" .'Tags[] | select(.Key == $BACKUP_DESTINATION).Value' --raw-output)
# check if bucket exists
# if not, create a bucket
echo "Checking if s3://${BUCKET} exists..."
aws s3api wait bucket-exists --bucket $BUCKET || (echo "s3://${BUCKET} does not exist, creating..."; aws s3 mb s3://${BUCKET})
TIMESTAMP=`date +%F-%H-%M-%S`
SNAPSHOT=${NOTEBOOK_NAME}_${TIMESTAMP}
echo "Backup up /home/ec2-user/SageMaker/ to s3://${BUCKET}/${SNAPSHOT}/"
aws s3 sync --exclude "*/lost+found/*" /home/ec2-user/SageMaker/ s3://${BUCKET}/${SNAPSHOT}/
exitcode=$?
echo $exitcode
if [ $exitcode -eq 0 ] || [ $exitcode -eq 2 ]
then
    TIMESTAMP=`date +%F-%H-%M-%S`
    echo "Created s3://${BUCKET}/${SNAPSHOT}/" > /home/ec2-user/SageMaker/BACKUP_COMPLETE
    echo "Completed at $TIMESTAMP" >> /home/ec2-user/SageMaker/BACKUP_COMPLETE
    aws s3 cp /home/ec2-user/SageMaker/BACKUP_COMPLETE s3://${BUCKET}/${SNAPSHOT}/BACKUP_COMPLETE
fi
EOF

chmod +x /home/ec2-user/backup.sh
chown ec2-user:ec2-user /home/ec2-user/backup.sh

# nohup to bypass the notebook instance timeout at start
sudo -u ec2-user nohup /home/ec2-user/backup.sh >>  /home/ec2-user/nohup.out 2>&1 & 
