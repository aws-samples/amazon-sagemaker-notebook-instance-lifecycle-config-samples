#     Copyright 2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
#     Licensed under the Apache License, Version 2.0 (the "License").
#     You may not use this file except in compliance with the License.
#     A copy of the License is located at
#
#         https://aws.amazon.com/apache-2-0/
#
#     or in the "license" file accompanying this file. This file is distributed
#     on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
#     express or implied. See the License for the specific language governing
#     permissions and limitations under the License.

import getopt
import json
import sys
from datetime import datetime

import boto3
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Usage
usageInfo = """Usage:
This scripts checks if a notebook is idle for X seconds if it does, it'll stop the notebook:
python autostop.py --time <time_in_seconds> [--port <jupyter_port>] [--ignore-connections]
Type "python autostop.py -h" for available options.
"""
# Help info
helpInfo = """-t, --time
    Auto stop time in seconds
-p, --port
    jupyter port
-c --ignore-connections
    Stop notebook once idle, ignore connected users
-h, --help
    Help information
"""

# Read in command-line parameters
idle = True
port = "8443"
ignore_connections = False
try:
    opts, args = getopt.getopt(
        sys.argv[1:], "ht:p:c", ["help", "time=", "port=", "ignore-connections"]
    )
    if len(opts) == 0:
        raise getopt.GetoptError("No input parameters!")
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(helpInfo)
            exit(0)
        if opt in ("-t", "--time"):
            time = int(arg)
        if opt in ("-p", "--port"):
            port = str(arg)
        if opt in ("-c", "--ignore-connections"):
            ignore_connections = True
except getopt.GetoptError:
    print(usageInfo)
    exit(1)

# Missing configuration notification
missingConfiguration = False
if not time:
    print("Missing '-t' or '--time'")
    missingConfiguration = True
if missingConfiguration:
    exit(2)


def is_idle(last_activity):
    last_activity = datetime.strptime(last_activity, "%Y-%m-%dT%H:%M:%S.%fz")
    if (datetime.now() - last_activity).total_seconds() > time:
        print("Kernel is idle. Last activity time = ", last_activity)
        return True
    else:
        print("Kernel is not idle. Last activity time = ", last_activity)
        return False


def is_terminal_state(response):
    for terminal in response:
        print(terminal)
        if is_idle(terminal["last_activity"]):
            return True
    return False


def get_notebook_name():
    log_path = "/opt/ml/metadata/resource-metadata.json"
    with open(log_path, "r") as logs:
        _logs = json.load(logs)
    return _logs["ResourceName"]


# This is hitting Jupyter's sessions API: https://github.com/jupyter/jupyter/wiki/Jupyter-Notebook-Server-API#Sessions-API
response = requests.get(f"https://localhost:{port}/api/sessions", verify=False)
data = response.json()
if len(data) > 0:
    for notebook in data:
        # Idleness is defined by Jupyter
        # https://github.com/jupyter/notebook/issues/4634
        if notebook["kernel"]["execution_state"] == "idle":
            if not ignore_connections:
                if notebook["kernel"]["connections"] == 0:
                    if not is_idle(notebook["kernel"]["last_activity"]):
                        idle = False
                else:
                    idle = False
                    print(
                        f"Notebook idle state set as {idle} because no kernel has been detected."
                    )
            else:
                if not is_idle(notebook["kernel"]["last_activity"]):
                    idle = False
                    print(
                        f"Notebook idle state set as {idle} since kernel connections are ignored."
                    )
        else:
            print("Notebook is not idle:", notebook["kernel"]["execution_state"])
            idle = False
else:
    client = boto3.client("sagemaker")
    uptime = client.describe_notebook_instance(
        NotebookInstanceName=get_notebook_name()
    )["LastModifiedTime"]
    if not is_idle(uptime.strftime("%Y-%m-%dT%H:%M:%S.%fz")):
        idle = False
        print(f"Notebook idle state set as {idle} since no sessions detected.")

# Check terminals is idle or not
response = requests.get(
    f"https://localhost:{port}/api/terminals",
    verify=False,
)
data = response.json()

terminal_idle = is_terminal_state(data) if data else True

idle = idle and terminal_idle

if idle:
    print("Closing idle notebook")
    client = boto3.client("sagemaker")
    client.stop_notebook_instance(NotebookInstanceName=get_notebook_name())
else:
    print("Kernel not idle. Pass.")
