#!/bin/bash

set -e

# OVERVIEW
# This script installs a single conda R package (bigmemory) in SageMaker R environment.
# To install an R package with conda, the package needs to be prefixed with 'r-'. For example, to install the package `shiny`, run 'conda install -c r r-shiny'.

sudo -u ec2-user -i <<'EOF'

source activate R

conda install -y -c r r-bigmemory 
conda deactivate
EOF
