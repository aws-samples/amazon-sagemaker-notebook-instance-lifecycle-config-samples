#!/bin/bash

set -e

# OVERVIEW
# This script enable Streamlit webapp to run on SageMaker notebook instance.
#
# By default Streamlit is installed in `python3` virtual environment. Start Streamlit server by running the following command in notebook terminal:
# - source activate python3
# - streamlit run app.py
#
# Streamlit web app can be accessed using the URL `{base_url}/proxy/{port}/` in a browser. With a slash at the end.
# E.g. https://{notebookname}.notebook.{region}.sagemaker.aws/proxy/8501/


sudo -u ec2-user -i <<'EOF'
# PARAMETERS
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv

# Disable nbserverproxy
jupyter serverextension disable --py nbserverproxy

cp /home/ec2-user/anaconda3/envs/JupyterSystemEnv/etc/jupyter/jupyter_notebook_config.json \
/home/ec2-user/anaconda3/envs/JupyterSystemEnv/etc/jupyter/jupyter_notebook_config.json.bk
sed 's/"nbserverproxy": true/"nbserverproxy": false/g' /home/ec2-user/anaconda3/envs/JupyterSystemEnv/etc/jupyter/jupyter_notebook_config.json.bk \
> /home/ec2-user/anaconda3/envs/JupyterSystemEnv/etc/jupyter/jupyter_notebook_config.json

# Uninstall nbserverproxy
pip uninstall nbserverproxy --yes

# Install jupyter-server-proxy
pip install jupyter-server-proxy

# Activate environment for Streamlit installation
ENVIRONMENT=python3
source /home/ec2-user/anaconda3/bin/activate "$ENVIRONMENT"
pip install streamlit

# Restart jupyter server
sudo initctl restart jupyter-server --no-wait

source /home/ec2-user/anaconda3/bin/deactivate


EOF

