#!/bin/bash
set -e
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
 
