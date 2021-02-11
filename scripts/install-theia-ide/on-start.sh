#!/bin/bash

###
#
# OVERVIEW
# 
# This script installs the Eclipse Theia IDE on a Jupyter notebook server.  Currently
# this script installs Theia IDE 1.1.0.  The Theia IDE supports many VS Code extensions
# and they can be installed from the web UI using the IDE's extension manager.
#
# To learn more about Theia IDE please visit https://theia-ide.org/
# 
# NOTES
#
# During execution this script will retrieve configuration files from the internet along
# with various NodeJS and Jupyter packages.  If deploying a notebook into a confined
# network environment you will need to alter this script to have access to the Theia IDE
# source and related packages.
#
# Please note that Theia is not a supported AWS product but is an open source software.
# This script is only a demonstration of how to install Theia IDE with Amazon SageMaker 
# notebooks.
#
# Also note that, once started, the Theia IDE will be built in the background, 
# independently of this script.  As such please allow up to 5 minutes after the 
# notebook has started for installation to complete.
#
###

set -e

sudo -u ec2-user -i <<'EOP'
#####################################
## INSTALL THEIA IDE FROM SOURCE
#####################################
EC2_HOME=/home/ec2-user
mkdir ${EC2_HOME}/theia && cd ${EC2_HOME}/theia
### begin by installing NVM, NodeJS v10, and Yarn
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.5/install.sh | bash
source ${EC2_HOME}/.nvm/nvm.sh
nvm install 10
nvm use 10
npm install -g yarn
### now compile Theia-IDE from source, retrieving the configuration package.json from GitHub
export NODE_OPTIONS=--max_old_space_size=4096
curl https://raw.githubusercontent.com/jpbarto/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/install-theia-ide/package.json -o ${EC2_HOME}/theia/package.json
nohup yarn &
#####################################
### Configure Theia defaults
#####################################
THEIA_PATH=$PATH
mkdir ${EC2_HOME}/.theia
mkdir -p ${EC2_HOME}/SageMaker/.theia
curl https://raw.githubusercontent.com/jpbarto/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/install-theia-ide/launch.json -o ${EC2_HOME}/SageMaker/.theia/launch.json
cat >${EC2_HOME}/.theia/settings.json <<EOS
{
    "workbench.iconTheme": "theia-file-icons",
    "terminal.integrated.inheritEnv": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "python.linting.pycodestyleEnabled": true,
    "python.linting.enabled": true
}
EOS
#####################################
### Integrate Theia IDE with Jupyter
#####################################
## CONFIGURE JUPYTER PROXY TO MAP TO THE THEIA IDE
JUPYTER_ENV=/home/ec2-user/anaconda3/envs/JupyterSystemEnv
source /home/ec2-user/anaconda3/bin/activate JupyterSystemEnv
cat >>${JUPYTER_ENV}/etc/jupyter/jupyter_notebook_config.py <<EOC
c.ServerProxy.servers = {
  'theia': {
    'command': ['yarn', '--cwd', '/home/ec2-user/theia', 'start', '/home/ec2-user/SageMaker', '--port', '{port}'],
    'environment': {'PATH': '${THEIA_PATH}'},
    'absolute_url': False,
    'timeout': 30
  }
}
EOC
pip install jupyter-server-proxy pylint autopep8 yapf pyflakes pycodestyle 'python-language-server[all]'
jupyter serverextension enable --py --sys-prefix jupyter_server_proxy
jupyter labextension install @jupyterlab/server-proxy
source /home/ec2-user/anaconda3/bin/deactivate
EOP

## RESTART THE JUPYTER SERVER
initctl restart jupyter-server --no-wait
