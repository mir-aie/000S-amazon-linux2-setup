#!/usr/bin/python3
# lastupdate: 2021-4-2 obata@mir-ai.co.jp

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
import random

from urllib.error import URLError, HTTPError
import datetime

AWS_INSTANCE_ID_GET_URL = 'http://169.254.169.254/latest/meta-data/instance-id/'
LOG_FILE = '/home/ec2-user/deploy/host_status.txt'
API_HASH_SEED = 'm1ra1eAp1Dep10y'

response = {}
instance_id = ''

proc_white_lists = [
    'php aritsan ',
    'php /var/www/production/',
    'php /var/www/staging/',
    'skyfish_',
    'python3 /home/ec2-user/',
]


def main(argvs):
    global instance_id
    global response

    response = init_response()
    response['aws_account_id'] = get_aws_account_id()
    response['instance_id'] = get_instance_id()
    response['cpu_load']  = get_cpu_load()
    response['free_disk'] = get_free_disk()
    response['free_mem']  = get_free_mem()
    response['proc_num']  = get_proc_num()
    response['top_proc']  = get_top_proc()

    #print (response)

    # 各サーバがAPIを叩くタイミングをずらす
    time.sleep(3 + random.random() * 30)

    put_host_status()

    report_exit()

def get_aws_account_id():
    cmd_results = run_cmd("/usr/bin/aws sts get-caller-identity".split())
    res = json.loads(cmd_results)
    if 'Account' in res:
        return res['Account']

    return ''

def get_cpu_load():
    cmd_results = run_cmd("/bin/uptime")
    for line in cmd_results.split("\n"):
        #print ("get_cpu_load", line)
        # 12:11:35 up 51 days,  4:07,  0 users,  load average: 0.00, 0.01, 0.05
        line = line.replace(',', '')
        t, up, d, days, h, u, users, load, average, min1, min5, min15 = line.split()

        return min15

    return 100

def get_free_disk():
    cmd_results = run_cmd("/bin/df -k .".split())
    for line in cmd_results.split("\n"):
        line = line.replace('%', '')
        # ファイルシス   1K-ブロック     使用   使用可 使用% マウント位置
        # /dev/nvme0n1p1    31444972 10816404 20628568   35% /
        f, b, u, a, free_disk, *m = line.split()

        if free_disk.isnumeric():
            return free_disk

    return 100

def get_free_mem():
    cmd_results = run_cmd("/bin/free".split())
    for line in cmd_results.split("\n"):
        line = line.replace('', '')
        #       total        used        free      shared  buff/cache   available
        # Mem:  3818856     2265468      958788       98832      594600     1187500
        # Swap:             0           0           0

        if 'Mem:' in line:
            typ, total, used, free, shared, buff_cache, available = line.split()
            total = int(total)
            available = int(available)
            if total > 0 and available >= 0:
                return (int)((available / total) * 100)

    return 100

def get_proc_num():
    cmd_results = run_cmd("/bin/ps -ef".split())
    line_cnt = len(cmd_results.split("\n"))

    return line_cnt - 1

def get_top_proc():
    global proc_white_lists

    cmd_results = run_cmd("/bin/top -c -b -n 1 -w 180".split())
    lines = cmd_results.split("\n")
    if len(lines) >= 8:
        for i in range(8, len(lines)):
            #     1 root      20   0  125452   3256   1872 S   0.0  0.1   2:53.78 /usr/lib/systemd/systemd --switched-root --syst+
            pid, user, pr, ni, virt, res, shr, s, cpu, mem, time, *command = lines[i].split()

            command_full = ' '.join(command)

            if float(cpu) >= 10:
                is_white = False
                for white in proc_white_lists:
                    if white in command_full:
                        is_white = True

                if not is_white:
                    return command_full

    return ''

def run_cmd(cmd):
    #print ('% ' + ' '.join(cmd))
    res = subprocess.run(cmd, stdout=subprocess.PIPE)
    return res.stdout.decode('utf-8').strip()
    #sys.stdout.buffer.write(res.stdout)

def abort(msg):
    response['message'] = msg

    log_write(msg)
    exit(1)

def report_exit():
    log_write(response['message'], True)
    exit(0)

def log_write(msg, detail = False):
    my_mkdir(LOG_FILE)

    with open(LOG_FILE, mode='a') as f:
        dt_now = datetime.datetime.now()
        dt_str = dt_now.strftime('%Y/%m/%d %H:%M:%S')
        response_str = json.dumps(response)
        if (detail):
            f.write(f"{dt_str}: {msg} : {response_str}\n")
        else:
            f.write(f"{dt_str}: {msg}\n")

def my_mkdir(filename):
    dirname = os.path.dirname(filename)
    if not os.path.isdir(dirname):
        os.makedirs(dirname)

def put_host_status():
    global response

    instance_id = response['instance_id']

    api_url = f"https://deploy.pub-sec.net/api/put_host_status/{instance_id}"
    #print (f"api_url = {api_url}")

    headers = {
        "Content-Type" : "application/json"
    }
    result = http_call_post(api_url, headers, response)
    print ("put_host_status", result)
    return result

def http_call_post(url, headers = {}, payload = {}):
    print ("http_call_post", url, payload)
    #print (headers)
    #print (payload)
    request_time = int(time.time())
    original = f"{request_time}{API_HASH_SEED}".encode('utf8')
    request_hash = hashlib.sha256(original).hexdigest()

    headers = {
        "Content-Type" : "application/json"
    }
    method = 'POST'
    params = payload
    params['rt'] = request_time
    params['rh'] = request_hash
    json_data = json.dumps(params).encode("utf-8")

    # ログファイルに吐き出し
    #print ("◇SERVER_REQUEST : " + json.dumps(params))

    request = urllib.request.Request(url, method=method, headers=headers, data=json_data)

    try:
        # サーバコール
        with urllib.request.urlopen(request, timeout=8) as response:

            # サーバとの通信に成功した
            response_body = response.read().decode("utf-8")
            log_write("◇SERVER_RESPONSE : " + response_body)
            return response_body

    except HTTPError as e:
        error_desc = e.read().decode("utf-8").replace("\n", "")
        log_write ("◇ERROR_RESPONSE : " + error_desc)

        return {}


    exit(0)

def get_instance_id():
    instance_id = http_call(AWS_INSTANCE_ID_GET_URL)
    #print (f"instance_id = {instance_id}")
    if not instance_id:
        abort(f"could not get instance_id")
    return instance_id

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

# キーがなくてもエラーで止まらないように関数を挟んでいます
def get_key(dic, key):
    if (key in dic):
        return str(dic[key])
    else:
        return str('')

def init_response():

    response = {
        'instance_id' : '',
        'cpu_load'    : '',
        'free_disk'   : '',
        'free_mem'    : '',
        'proc_num'    : '',
        'message'     : '',
        'success'     : 'Y',
    }

    return response

if __name__ == "__main__":
    main(sys.argv[1:])

