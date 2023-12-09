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

# 使用方法とヘルプ情報
usageInfo = """Usage:
This script checks if a notebook and terminal are idle for X seconds and if so, it'll stop the notebook:
python autostop.py --time <time_in_seconds> [--port <jupyter_port>] [--ignore-connections]
Type "python autostop.py -h" for available options.
"""
helpInfo = """-t, --time
    Auto stop time in seconds
-p, --port
    Jupyter port
-c --ignore-connections
    Stop notebook once idle, ignore connected users
-h, --help
    Help information
"""

# コマンドラインパラメータの読み込み
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

if not time:
    print("Missing '-t' or '--time'")
    exit(2)


def is_idle(last_activity):
    last_activity = datetime.strptime(last_activity, "%Y-%m-%dT%H:%M:%S.%fZ")
    return (datetime.now() - last_activity).total_seconds() > time


def get_latest_terminal_activity():
    response = requests.get(f"https://localhost:{port}/api/terminals", verify=False)
    terminals = response.json()
    latest_activity = None
    for terminal in terminals:
        activity_time = datetime.strptime(
            terminal["last_activity"], "%Y-%m-%dT%H:%M:%S.%fZ"
        )
        if latest_activity is None or activity_time > latest_activity:
            latest_activity = activity_time
    return latest_activity


def get_notebook_name():
    log_path = "/opt/ml/metadata/resource-metadata.json"
    with open(log_path, "r") as logs:
        _logs = json.load(logs)
    return _logs["ResourceName"]


# ノートブックセッションのアイドル状態をチェック
response = requests.get(f"https://localhost:{port}/api/sessions", verify=False)
notebooks = response.json()
notebook_idle = all(
    notebook["kernel"]["execution_state"] == "idle"
    and (ignore_connections or notebook["kernel"]["connections"] == 0)
    and is_idle(notebook["kernel"]["last_activity"])
    for notebook in notebooks
)

# ターミナルセッションのアイドル状態をチェック
latest_terminal_activity = get_latest_terminal_activity()
terminal_idle = not latest_terminal_activity or is_idle(
    latest_terminal_activity.isoformat()
)

# 両方がアイドル状態であればインスタンスを停止
if notebook_idle and terminal_idle:
    print("Closing idle notebook and terminal")
    client = boto3.client("sagemaker")
    client.stop_notebook_instance(NotebookInstanceName=get_notebook_name())
else:
    print("Notebook or terminal not idle. Pass.")
