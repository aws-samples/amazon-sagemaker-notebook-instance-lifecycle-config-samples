import requests
from datetime import datetime
import getopt, sys
import urllib3
import boto3
import json
import os
import GPUtil
import psutil
import json

from io import StringIO 

class Capturing(list):
    def __enter__(self):
        self._stdout = sys.stdout
        sys.stdout = self._stringio = StringIO()
        return self
    def __exit__(self, *args):
        self.extend(self._stringio.getvalue().splitlines())
        del self._stringio    # free up some memory
        sys.stdout = self._stdout

# OVERVIEW
# This script is adapted from https://github.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/blob/master/scripts/auto-stop-idle/autostop.py. Modifications are made to calculate four quantities (CPU utilization, CPU memory utilization, GPU utilization, GPU memory utilization) at regular intervals defined by the cron expression of the on-start script. These aggregate values are also added as tags to the notebook instance so users can get an idea of what the utilization looks like without accessing the actual jupyter notebook. Additionally, a cloudwatch agent logs more detailed metrics for users to monitor notebook instance usage. Fianlly, an example query (commented out) is provided to use within Cost Explorer to visualize aggregate metrics. 

idle = True
port = '8443'

# Ignore if any browsers or clients are open
ignore_connections = False

# Threshold for deciding idle value
time_threshold = 4*60*60 # 4 hours in seconds

# Force shutdown if conditions are true, or just log to output
force_shutdown = False

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_notebook_name():
    log_path = '/opt/ml/metadata/resource-metadata.json'
    with open(log_path, 'r') as logs:
        _logs = json.load(logs)
    return _logs['ResourceName']


def get_notebook_resource_arn():
    log_path = '/opt/ml/metadata/resource-metadata.json'
    with open(log_path, 'r') as logs:
        _logs = json.load(logs)
    return _logs['ResourceArn']


# When is a notebook considered idle by the Notebooks API? - https://github.com/jupyter/notebook/issues/4634

# The way it works at present is that the kernel sends a 'busy' message when it starts executing a request, and an 'idle' message when it finishes. So it's idle if there's not code running. The 'while True' loop would leave it busy.

# Code execution isn't the only kind of request, though. Among other things, when you open a notebook in a tab, it will make a kernel info request, which will reset the timer.


def is_idle(last_activity):
    last_activity = datetime.strptime(last_activity,"%Y-%m-%dT%H:%M:%S.%fz")
    if (datetime.now() - last_activity).total_seconds() > time_threshold:
        print('Notebook is idle. Last activity time = ', last_activity)
        return True
    else:
        print('Notebook is not idle. Last activity time = ', last_activity)
        return False


response = requests.get('https://localhost:'+port+'/api/sessions', verify=False)
data = response.json()
print(data)
if len(data) > 0:
    
    print("Using Jupyter Notebook API since request was successful")
    for notebook in data:

        if notebook['kernel']['execution_state'] == 'idle':
            if not ignore_connections:
                if notebook['kernel']['connections'] == 0:
                    if not is_idle(notebook['kernel']['last_activity']):
                        idle = False
                else:
                    idle = False #If any connection exists, notebook is not idling
            else:
                if not is_idle(notebook['kernel']['last_activity']):
                    idle = False #If last activity is recent, notebook is not idling
        else:
            print('Notebook is not idle:', notebook['kernel']['execution_state'])
            idle = False
else:
    print("Using SageMaker instance last modified time")
    client = boto3.client('sagemaker')
    uptime = client.describe_notebook_instance(
        NotebookInstanceName=get_notebook_name()
    )['LastModifiedTime']
    if not is_idle(uptime.strftime("%Y-%m-%dT%H:%M:%S.%fz")):
        idle = False
        
        
#CPU, Mem and GPU utilization
print(f"Utilization metrics at {datetime.now()}")

total_cpu_util = psutil.cpu_percent()
total_mem_util = psutil.virtual_memory().percent
print(f"CPU utilization = {total_cpu_util}%")
print(f"Memory utilization = {total_mem_util}%")
# Testing the GPUtil library for both GPU performance details
num_gpu = 0
try:
    print("GPU utilization = ")
    with Capturing() as output:
        GPUtil.showUtilization()
    

    if len(output)==1:
        print("Found no GPUs")
    else:
        print(f"Found {len(output) -2} GPUs:") # Output is formatted, -2 is one for header and another for separator '---'
        num_gpu = len(output)-2
        total_gpu_util = 0
        total_gpumem_util = 0
        for i in range(2,len(output)):
            tmp = output[i].split('|')
            # print(tmp)
            print(f"GPU{tmp[1]} mem = {tmp[-2]}")
            print(f"GPU{tmp[1]} util = {tmp[-4]}")
            total_gpu_util+=int(tmp[-4].split('%')[0])
            total_gpumem_util+=int(tmp[-2].split('%')[0])
        
        print(f"Total GPU Mem Utilization = {total_gpumem_util}/{(len(output) -2)*100} %")
        print(f"Total GPU Utilization = {total_gpu_util}/{(len(output) -2)*100} %")
        

except Exception as e:
    print("Did not capture GPU utilization")
    print(e)
    total_gpu_util = 0
    total_gpumem_util = 0
    


# Updating tags
client = boto3.client('sagemaker')
response = client.add_tags(
    ResourceArn=get_notebook_resource_arn(),
    Tags=[
    {
        'Key': 'total_cpu_util',
        'Value': str(total_cpu_util)
    },
    {
        'Key': 'total_mem_util',
        'Value': str(total_mem_util)
    },
    {
        'Key': 'total_gpu_util',
        'Value': str(total_gpu_util)
    },
    {
        'Key': 'total_gpumem_util',
        'Value': str(total_gpumem_util)
    }
    ])
    
    
# Add conditions here:

shutdown = False

if not idle and num_gpu>0 and 0 < total_gpu_util < 20:
    print("Recommend using a smaller GPU instance")
    
if idle and total_cpu_util < 10 and total_mem_util < 10 and force_shutdown:
    print(f'Closing idle notebook since Jupyter Kernels idling is {idle}, total CPU utilization is {total_cpu_util} and total Memory utilization is {total_mem_util}')
    client = boto3.client('sagemaker')
    client.stop_notebook_instance(
        NotebookInstanceName=get_notebook_name()
    )

else:
    print(f"Notebook is active at {datetime.now()}. Updated util metrics")
    print(f'NOT closing idle notebook since Jupyter Kernels idling is {idle}, total CPU utilization is {total_cpu_util} and total Memory utilization is {total_mem_util}')
    

print(json.dumps({"CPU_util":total_cpu_util, "Mem_util":total_mem_util, "GPU_util":total_gpu_util, "GPU_mem_util":total_gpumem_util}))

client = boto3.client('sagemaker')
response = client.list_tags(
    ResourceArn=get_notebook_resource_arn()
)
tags = response['Tags']
tagdict = {}

for tag in tags:
    tagdict[tag['Key']] = tag['Value']
print("---")
print(tagdict)


try:
    print("If available, log running average utilization ...")
    print(float(tagdict['total_cpu_util']) + float(total_cpu_util))

    print(json.dumps({
        'avg_CPU_util' : int((float(tagdict['total_cpu_util']) + float(total_cpu_util))/2.),
        'avg_Mem_util' : int((float(tagdict['total_mem_util']) + float(total_mem_util))/2.),
        'avg_GPU_util' : int((float(tagdict['total_gpu_util']) + float(total_gpu_util))/2.),
        'avg_GPUmem_util' : int((float(tagdict['total_gpumem_util']) + float(total_gpumem_util))/2.),
    }))
    
except Exception as e:
    print('Historical values not available')
    print(e)
    
    
# In cloudwatch log insights, use the a query similar to the following:
'''
fields @timestamp, avg_CPU_util
| filter @logStream="notebook-name/jupyter.log"
| stats avg(avg_CPU_util),avg(avg_Mem_util),avg(avg_GPU_util),avg(avg_GPUmem_util),count() by bin(60s)
| sort @timestamp asc 
'''



    
