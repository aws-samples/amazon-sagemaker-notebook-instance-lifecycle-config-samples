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

# 使用方法
usageInfo = """Usage:
This script checks if a notebook is idle for X seconds and if it does, it'll stop the notebook:
python autostop.py --time <time_in_seconds> [--port <jupyter_port>] [--ignore-connections]
Type "python autostop.py -h" for available options.
"""

# ヘルプ情報
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
        sys.argv[1:],
        "ht:p:c",
        ["help", "time=", "port=", "ignore-connections"],
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

# 構成情報が不足している場合の通知
missingConfiguration = False
if not time:
    print("Missing '-t' or '--time'")
    missingConfiguration = True
if missingConfiguration:
    exit(2)


# 最後のアクティビティ時間を取得する関数
def get_last_activity():
    notebook_response = requests.get(
        f"https://localhost:{port}/api/sessions", verify=False
    )
    notebook_data = notebook_response.json()
    terminal_response = requests.get(
        f"https://localhost:{port}/api/terminals", verify=False
    )
    terminal_data = terminal_response.json()

    last_activity = datetime.min

    # Jupyter Notebookのセッションから最後のアクティビティ時間を取得
    for notebook in notebook_data:
        activity_time = datetime.strptime(
            notebook["kernel"]["last_activity"], "%Y-%m-%dT%H:%M:%S.%fz"
        )
        if activity_time > last_activity:
            last_activity = activity_time

    # ターミナルセッションが存在する場合、現在時刻を最後のアクティビティ時間として扱う
    if len(terminal_data) > 0:
        last_activity = datetime.now()

    return last_activity


# ノートブックの名前を取得する関数
def get_notebook_name():
    log_path = "/opt/ml/metadata/resource-metadata.json"
    with open(log_path, "r") as logs:
        _logs = json.load(logs)
    return _logs["ResourceName"]


# アイドル状態のチェック
last_activity = get_last_activity()
if (datetime.now() - last_activity).total_seconds() > time:
    print(
        "Jupyter has been idle for more than specified time. Last activity time = ",
        last_activity,
    )
    idle = True
else:
    print("Jupyter is not idle. Last activity time = ", last_activity)
    idle = False

# インスタンスの停止処理
if idle:
    print("Closing idle notebook")
    client = boto3.client("sagemaker")
    client.stop_notebook_instance(NotebookInstanceName=get_notebook_name())
else:
    print("Notebook not idle. Pass.")
