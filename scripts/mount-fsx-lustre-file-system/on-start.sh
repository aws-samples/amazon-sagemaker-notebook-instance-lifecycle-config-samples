#!/bin/bash

set -e

# OVERVIEW
# This script mounts a FSx for Lustre file system to the Notebook Instance at the /fsx directory based off
# the DNS and Mount name parameters.
#
# This script assumes the following:
#   1. There's an FSx for Lustre file system created and running
#   2. The FSx for Lustre file system is accessible from the Notebook Instance
#       - The Notebook Instance has to be created on the same VPN as the FSx for Lustre file system
#       - The subnets and security groups have to be properly set up.  Same values for file system and notebook.
#   3. Set the FSX_DNS_NAME parameter below to the DNS name of the FSx for Lustre file system.
#   4. Set the FSX_MOUNT_NAME parameter below to the Mount name of the FSx for Lustre file system. It's not the name you appointed at creation.


#sudo -u ec2-user -i <<'EOF'

# PARAMETERS
FSX_DNS_NAME=fs-your-fs-id.fsx.your-region.amazonaws.com
FSX_MOUNT_NAME=your-mount-name

# First, we need to install the lustre libraries
# this command is dependent on current running Amazon Linux and JupyterLab versions
CURR_VERSION_AL=$(cat /etc/system-release)
CURR_VERSION_JS=$(jupyter --version)

if [[ $CURR_VERSION_JS == *$"jupyter_core     : 4.9.1"* ]] && [[ $CURR_VERSION_AL == *$" release 2018"* ]]; then
	sudo yum install -y lustre-client
else
	sudo amazon-linux-extras install -y lustre
fi

# Now we can create the mount point and mount the file system
sudo mkdir -p /fsx

sudo mount -t lustre -o noatime,flock $FSX_DNS_NAME@tcp:/$FSX_MOUNT_NAME /fsx

# Let's make sure we have the appropriate access to the directory
sudo chmod go+rw /fsx

#EOF
