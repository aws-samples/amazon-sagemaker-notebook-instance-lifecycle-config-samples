#!/bin/bash

set -e

# OVERVIEW
# This script fixes a problem in SageMaker Notebook instances where Jupyter fails to export a notebook
# directly to PDF. nbconvert depends on XeLaTeX and several LaTeX packages that are non-trivial to 
# install because `tlmgr` is not included with the texlive packages provided by yum.

sudo yum install -y texlive*
sudo -u ec2-user -i <<EOF
unset SUDO_UID

ln -s /home/ec2-user/SageMaker/.texmf /home/ec2-user/texmf

EOF
