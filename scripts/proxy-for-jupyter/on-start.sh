#!/bin/bash
 
set -e

su - ec2-user -c "mkdir /home/ec2-user/.ipython/ && mkdir /home/ec2-user/.ipython/profile_default/ && mkdir /home/ec2-user/.ipython/profile_default/startup/ && touch /home/ec2-user/.ipython/profile_default/startup/00-startup.py"

echo "export http_proxy='http://proxy.local:3128'" | tee -a /home/ec2-user/.profile >/dev/null
echo "export https_proxy='http://proxy.local:3128'" | tee -a /home/ec2-user/.profile >/dev/null
echo "export no_proxy='s3.amazonaws.com,127.0.0.1,localhost'" | tee -a /home/ec2-user/.profile >/dev/null

# Now we change the terminal shell to bash
echo "c.NotebookApp.terminado_settings={'shell_command': ['/bin/bash']}" | tee -a /home/ec2-user/.jupyter/jupyter_notebook_config.py >/dev/null

echo "import sys,os,os.path" | tee -a /home/ec2-user/.ipython/profile_default/startup/00-startup.py >/dev/null
echo "os.environ['HTTP_PROXY']="\""http://proxy.local:3128"\""" | tee -a /home/ec2-user/.ipython/profile_default/startup/00-startup.py >/dev/null
echo "os.environ['HTTPS_PROXY']="\""http://proxy.local:3128"\""" | tee -a /home/ec2-user/.ipython/profile_default/startup/00-startup.py >/dev/null
echo "os.environ['NO_PROXY']="\""s3.amazonaws.com,127.0.0.1,localhost"\""" | tee -a /home/ec2-user/.ipython/profile_default/startup/00-startup.py >/dev/null

# Next, we reboot the system so the bash shell setting can take effect. This reboot is only required when applying proxy settings to the shell environment as well.
# If only setting up Jupyter notebook proxy, you can leave this out

reboot
