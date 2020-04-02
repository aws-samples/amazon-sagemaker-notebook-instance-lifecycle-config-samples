#!/bin/bash

set -e

# OVERVIEW:
# This script adds an alternate PyPi repository to be used by `pip install ...`. 
# 
# You can use this script to connect to your organization's private PyPi repository. 
# There are two common reasons for using private PyPi repositories and this script is 
# set up to support both.
# 1. You have a repository that you want to use to host your organization's own packages
#    *in addition to* the main pypi.org repository. In that case, set DISABLE_PYPI, below,
#    to false and the setup will allow `pip install` to search both repositories.
# 2. You have a repository that hosts a set of curated packages that are approved for use
#    in your organization. This is common in organizations that have strict regulatory
#    or security requirements. In this case, set DISABLE_PYPI to true and pip will be
#    be configured to search *only* your private repository.
#
# For other requirements (like multiple repositories), feel free to edit this script to
# meet your needs.
#
# See the pip documentation at https://pip.pypa.io/en/stable/user_guide/#config-file for 
# details on how the pip configuration file works.

# The URL of your repository
PYPI_URL=<Your respository url here>

# If DISABLE_PYPI is true, pip will ignore the pypi.org repository and only use the defined
# repository. If it is false, pip will use the defined repository *in addition to* 
# pypi.org
DISABLE_PYPI=false

# If ADD_TRUST is true, tell pip to trust the specified server even if the certificate
# doesn't validate.
ADD_TRUST=true

if [ "$DISABLE_PYPI" == "true" ]
then
    extra=""
else
    extra="extra-"
fi

if [ "$ADD_TRUST" == "true" ]
then
    pypi_host=$(sed 's%^[^/]*//\([^/:]*\)[:/].*$%\1%' <<< "${PYPI_URL}")
    trusted_host="trusted-host = ${pypi_host}"
else
    trusted_host=""
fi

mkdir ~ec2-user/.pip

cat > ~ec2-user/.pip/pip.conf <<END
[global]
${extra}index-url = ${PYPI_URL}
${trusted_host}
END

chown -R ec2-user:ec2-user ~ec2-user/.pip