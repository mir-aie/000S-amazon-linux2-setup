#!/usr/bin/python3
# lastupdate: 2020-12-26 12:51 obata@miraie

import sys
import json
import re
import subprocess
import os
import glob
import argparse
import socket
import urllib.request
import urllib.parse
import shutil
import time
import hashlib

from urllib.error import URLError, HTTPError
import datetime

AWS_INSTANCE_ID_GET_URL = 'http://169.254.169.254/latest/meta-data/instance-id/'
FINISHED_REQUEST_FILE = '/home/ec2-user/deploy/remote_deploy_finished_request_id.txt'
LOG_FILE = '/home/ec2-user/deploy/remote_deploy_log.txt'
API_HASH_SEED = 'm1ra1eAp1Dep10y'

response = {}
instance_id = ''

def main(argvs):
    global instance_id
    global response

    for app_code in argvs:

        # Make hash for authorization
        request_time = int(time.time())
        original = f"{request_time}{API_HASH_SEED}{app_code}".encode('utf8')
        print (f"update_env() original {original}")
        request_hash = hashlib.sha256(original).hexdigest()

        # call deploy api to get latest production env.
        api_url = f"https://deploy.pub-sec.net/api/get_env/{app_code}?rh={request_hash}&rt={request_time}"
        print (f"skyfish_setup_env api_url : {api_url}")

        headers = {
            "Content-Type" : "application/json"
        }

        result = http_call(api_url, headers)

        if not result:
            #log_write(f"api return empty.")
            print ("skyfish_setup_env abort : api result empty")

        if '{' not in result:
            print ("skyfish_setup_env abort : api result has no {")
            return

        cmd = json.loads(result)

        if ('success' not in cmd):
            print ("skyfish_setup_env abort : api result has no success")
            return

        if ('production_env' not in cmd):
            print ("skyfish_setup_env abort : api result has no production_env")
            return

        production_env = cmd['production_env']

        # Check if env file contains proper entry

        if ('APP_NAME' not in production_env):
            print ("skyfish_setup_env abort : .env has no APP_NAME")
            return

        # backup current env file
        tgt_path = ".env"

        if os.path.exists(tgt_path):
            # Make backup
            dt_now = datetime.datetime.now()
            dt_str = dt_now.strftime('-%Y%m%d-%H%M%S')
            backup_path = tgt_path + dt_str
            shutil.copyfile(tgt_path, backup_path)

        # Overwrite env file in test .env
        with open(tgt_path, mode='w') as f:
            f.write(production_env)
            print (f"overwrite {tgt_path}")

def http_call(url, headers = {}):

    request = urllib.request.Request(url, method='GET', headers=headers)

    try:
        with urllib.request.urlopen(request) as response:

            response_body = response.read().decode("utf-8")
            return response_body

    except Exception as e:
        #import traceback
        #traceback.print_exc()
        print(e, 'http_call : error occurred', url)

        # 一旦サーバにおくって、サーバからパーミッションエラーを返してもらう
        return ''

def abort(msg):
    print (msg)
    exit(1)

if __name__ == "__main__":
    main(sys.argv[1:])
