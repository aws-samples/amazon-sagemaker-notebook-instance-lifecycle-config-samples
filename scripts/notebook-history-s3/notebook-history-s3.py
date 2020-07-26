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

import requests
from datetime import datetime
import getopt, sys
import boto3
import json
import sagemaker
import urllib3
import logging


urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Usage
usageInfo = """Usage:
This scripts gets the sqllite database of sessions and jupyter history and writes the spllite files to S3:
python log_notebook_history. Type "python autostop.py -h" for available options.
"""

# Help info
helpInfo = """
-h, --help
    Help information
"""
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger()
logger.addHandler(logging.FileHandler('/var/log/notebook_history_s3.log', 'a'))

# Read in command-line parameters
try:
    opts, args = getopt.getopt(sys.argv[1:], "h", ["help"])
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print(helpInfo)
            exit(0)
except getopt.GetoptError:
    print(usageInfo)
    exit(1)

def get_notebook_name():
    log_path = "/opt/ml/metadata/resource-metadata.json"
    with open(log_path, "r") as logs:
        _logs = json.load(logs)
    return _logs["ResourceName"]

sagemaker_session = sagemaker.Session()
s3 = boto3.client("s3")
bucket = sagemaker_session.default_bucket()
key = "notebooks/{}/history/{}/history.sqlite".format(get_notebook_name(), datetime.now().strftime("%Y%m%d-%H%M%S"))

logger.info("Writing history.sqlite to {}/{}".format(bucket,key))
with open('/home/ec2-user/.ipython/profile_default/history.sqlite', 'rb') as data:
    s3.upload_fileobj(data, bucket, key)
