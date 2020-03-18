#!/bin/bash

set -e

# OVERVIEW
# This script mounts a FSx for Lustre file system to the Notebook Instance at the /fsx directory based off
# the DNS and mount name parameters.
#
# This script assumes the following:
#   1. There's an FSx for Lustre file system created and running
#   2. The FSx for Lustre file system is accessible from the Notebook Instance
#       - The Notebook Instance has to be created on the same VPN as the FSx for Lustre file system
#       - The subnets and security groups have to be properly set up
#   3. Set the FSX_DNS_NAME parameter below to the DNS name of the FSx for Lustre file system.
#   4. Set the FSX_MOUNT_NAME parameter below to the Mount name of the FSx for Lustre file system.

# PARAMETERS
FSX_DNS_NAME=fs-your-fs-id.fsx.your-region.amazonaws.com
FSX_MOUNT_NAME=your-mount-name

# First, we need to install the lustre-client libraries
sudo yum install -y lustre-client

# Now we can create the mount point and mount the file system
sudo mkdir /fsx
sudo mount -t lustre -o noatime,flock $FSX_DNS_NAME@tcp:/$FSX_MOUNT_NAME /fsx

# Let's make sure we have the appropriate access to the directory
sudo chmod go+rw /fsx
