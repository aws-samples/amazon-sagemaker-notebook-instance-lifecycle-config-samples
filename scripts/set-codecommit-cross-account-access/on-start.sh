#!/bin/bash

set -e

# OVERVIEW
# This script sets cross-account CodeCommit access, so you can work on repositories hosted in another account.
# You'll need to create a role in AccountA granting repositories access to AccountB as instructed here:
# https://docs.aws.amazon.com/sagemaker/latest/dg/nbi-git-cross.html
# More information about the credential helper here:
# https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-https-unixes.html#setting-up-https-unixes-credential-helper

# PARAMETERS
ROLE_ARN=arn:aws:iam::CodeCommitAccount:role/CrossAccountRepositoryContributorRole
REGION=us-east-1

sudo -u ec2-user -i <<EOF

cat >>/home/ec2-user/.aws/config <<-END_CAT
	[profile CrossAccountAccessProfile]
	region = $REGION
	role_arn = $ROLE_ARN
	credential_source = Ec2InstanceMetadata
	output = json
END_CAT

git config --global credential.helper '!aws --profile CrossAccountAccessProfile codecommit credential-helper $@'

EOF
