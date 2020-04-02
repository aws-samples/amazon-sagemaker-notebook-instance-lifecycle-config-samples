#!/bin/bash

set -e

# OVERVIEW
# This script enables Jupyter to export a notebook directly to PDF.
# nbconvert depends on XeLaTeX and several LaTeX packages that are non-trivial to
# install because `tlmgr` is not included with the texlive packages provided by yum.

# REQUIREMENTS
# Internet access is required in on-create.sh in order to fetch the latex libraries from the ctan mirror.

sudo yum install -y texlive*
sudo -u ec2-user -i <<EOF
unset SUDO_UID

ln -s /home/ec2-user/SageMaker/.texmf /home/ec2-user/texmf

EOF
