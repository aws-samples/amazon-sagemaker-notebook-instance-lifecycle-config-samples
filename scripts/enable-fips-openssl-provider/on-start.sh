#!/bin/bash

# Iterate through each conda environment
for ENV in /home/ec2-user/anaconda3/envs/*; do
   ENV_NAME=$(basename $ENV)
   # Skip any non-directory and JupyterSystemEnv
   if [[ ! -d "$ENV" || $ENV_NAME == "JupyterSystemEnv" ]]; then
       continue
   fi

   # Construct the path to the openssl.cnf file within the environment
   openssl_cnf_path="$ENV/ssl/openssl.cnf"

   # Check if the openssl.cnf file exists
   if [[ -f "$openssl_cnf_path" ]]; then
       # Use sed to make the required modifications
       sed -i.bak 's|^# \.include fipsmodule\.cnf|\.include /home/ec2-user/anaconda3/envs/'"$ENV_NAME"'/ssl/fipsmodule.cnf|' "$openssl_cnf_path"
       sed -i.bak 's|^# fips = fips_sect|fips = fips_sect|' "$openssl_cnf_path"
       sed -i.bak 's|^# activate = 1|activate = 1|' "$openssl_cnf_path"
       sed -i.bak '/providers = provider_sect/a\
alg_section = algorithm_sect' "$openssl_cnf_path"
       sed -i.bak '/activate = 1/a\
[algorithm_sect]\
default_properties = fips=yes' "$openssl_cnf_path"

       echo "Updated openssl.cnf at $openssl_cnf_path"
   else
       echo "Warning: openssl.cnf file not found at $openssl_cnf_path"
   fi
done
