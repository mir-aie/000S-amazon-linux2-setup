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

    response = init_response()
    response['instance_id'] = get_instance_id()

    command = get_command()
    response['request_id'] = command['request_id']
    response['app_code'] = command['app_code']
    response['command'] = command['command']
    response['options'] = command['options']

    # 今回のリクエストIDをとる
    request_id = command['request_id']
    app_code = command['app_code']
    type = command['command']

    # これまでに完了したリクエストIDをとる
    finished_request_id = get_finished_request_id()
    #print (f"finished_request_id : {finished_request_id}")

    # これまでに終わったリクエストIDより、今回のリクエストが小さいか同じだったら、無視して終了
    if (int(finished_request_id) >= int(request_id)):
        #get_git_revision(app_code)
        #abort(f"request {request_id} already done")
        #log_write(f"finished_request_id : {finished_request_id}")
        exit(0)

    if not has_app(app_code):
        #log_write(f"not having app : {app_code}")
        exit(0)

    if type == 'update':
        exec_update_test(app_code)

    elif type == 'deploy':
        exec_deploy(app_code)

    elif type == 'rollback':
        exec_rollback(app_code)

    git_revision = get_git_revision(app_code)

    save_finished_request_id()

    response['success'] = 'Y'

    report_exit()

def exec_update_test(app_code):
    tgt_dir = f"/var/www/production/{app_code}/test"
    os.chdir(tgt_dir)

    cmd = "/usr/bin/git pull"
    result1 = run_cmd(cmd.split())

    result2 = update_env(app_code)

    cmd = "/usr/local/bin/composer install --no-dev"
    result3 = run_cmd(cmd.split())

    cmd = "/usr/bin/php artisan optimize:clear"
    result4 = run_cmd(cmd.split())

    cmd = "/usr/bin/php artisan config:cache"
    result5 = run_cmd(cmd.split())

    cmd = "/usr/bin/php artisan route:cache"
    result6 = run_cmd(cmd.split())

    cmd = "/usr/bin/php artisan view:cache"
    result7 = run_cmd(cmd.split())

    cmd = "/usr/local/bin/composer dump-autoload --optimize"
    result8 = run_cmd(cmd.split())

    cmd = "sudo /usr/local/bin/supervisorctl restart"
    result9 = run_cmd(cmd.split())

    cmd = "touch storage/logs/laravel.log"
    result10 = run_cmd(cmd.split())

    cmd = "sudo /bin/chmod -R a+w storage"
    result11 = run_cmd(cmd.split())

    cmd = "sudo /bin/chmod -R a+w bootstrap/cache"
    result12 = run_cmd(cmd.split())

    response['message'] = 'Update OK'

def exec_deploy(app_code):
    global response;

    tgt_dir = f"/var/www/production/{app_code}"
    os.chdir(tgt_dir)

    cmd = "ls --full-time sky/.git/FETCH_HEAD"
    result_sky = run_cmd(cmd.split())

    cmd = "ls --full-time fish/.git/FETCH_HEAD"
    result_fish = run_cmd(cmd.split())

    #print (f"sky  = {result_sky}" )
    #print (f"fish = {result_fish}" )

    if (result_sky > result_fish):
        cmd = "ln -nfs sky live"
        run_cmd(cmd.split())

        cmd = "ln -nfs fish test"
        run_cmd(cmd.split())

        #print (f"sky goes live")
    else:
        cmd = "ln -nfs fish live"
        run_cmd(cmd.split())

        cmd = "ln -nfs sky test"
        run_cmd(cmd.split())

        #print (f"fish goes live")

    response['message'] = 'Deploy OK'

def exec_rollback(app_code):
    global response;

    tgt_dir = f"/var/www/production/{app_code}"
    os.chdir(tgt_dir)

    cmd = "ls --full-time sky/.git/FETCH_HEAD"
    result_sky = run_cmd(cmd.split())

    cmd = "ls --full-time fish/.git/FETCH_HEAD"
    result_fish = run_cmd(cmd.split())

    #print (f"sky  = {result_sky}" )
    #print (f"fish = {result_fish}" )

    if (result_sky < result_fish):
        cmd = "ln -nfs sky live"
        run_cmd(cmd.split())

        cmd = "ln -nfs fish test"
        run_cmd(cmd.split())

        #print (f"sky goes live")
    else:
        cmd = "ln -nfs fish live"
        run_cmd(cmd.split())

        cmd = "ln -nfs sky test"
        run_cmd(cmd.split())

        #print (f"fish goes live")

    response['message'] = 'Rollback OK'

def get_git_revision(app_code):

    get_git_rev(app_code, 'test')
    get_git_rev(app_code, 'live')

def get_git_rev(app_code, stage):
    global response

    tgt_dir = f"/var/www/production/{app_code}/{stage}"
    os.chdir(tgt_dir)

    cmd = "/usr/bin/git rev-parse HEAD"
    git_rev = run_cmd(cmd.split())
    response[stage + "_git_revision"] = git_rev

    #print (f"get_git_rev {app_code}, {stage}, {git_rev}")

    cmd = f"/usr/bin/git log -n 1 {git_rev}"
    git_detail = run_cmd(cmd.split())
    git_details = git_detail.split("\n")
    response[stage + "_last_pull_time"] = ''
    response[stage + "_last_commit_time"] = git_details[2]
    response[stage + "_last_commit_time"] = response[stage + "_last_commit_time"].replace('Date: ', '')

    response[stage + "_last_commit_msg"] = git_details[3:]
    response[stage + "_last_commit_msg"] = ''.join(response[stage + "_last_commit_msg"]).strip()

    #print (f"git_detail")
    #print (response[stage + "_last_commit_at"])
    #print (response[stage + "_last_commit_msg"])

def run_cmd(cmd):
    #print ('% ' + ' '.join(cmd))
    res = subprocess.run(cmd, stdout=subprocess.PIPE)
    return res.stdout.decode('utf-8').strip()
    #sys.stdout.buffer.write(res.stdout)

def abort(msg):
    response['message'] = msg

    log_write(msg)
    put_result()
    exit(1)

def report_exit():
    log_write(response['message'], True)
    put_result()
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

def has_app(app_code):
    dir = f"/var/www/production/{app_code}"

    return os.path.isdir(dir)

def get_finished_request_id():
    if (os.path.isfile(FINISHED_REQUEST_FILE)):
        with open(FINISHED_REQUEST_FILE) as f:
            v = f.read()
            if str.isdecimal(v):
                return int(v)
    return 0

def my_mkdir(filename):
    dirname = os.path.dirname(filename)
    if not os.path.isdir(dirname):
        os.makedirs(dirname)

def save_finished_request_id():

    my_mkdir(FINISHED_REQUEST_FILE)
    # 今回終わったリクエストIDを保存する
    with open(FINISHED_REQUEST_FILE, mode='w') as f:
        f.write(str(int(response['request_id'])))

def get_command():
    instance_id = response['instance_id']
    api_url = f"https://deploy.pub-sec.net/api/get_request/{instance_id}"
    #print (f"api_url = {api_url}")

    headers = {
        "Content-Type" : "application/json"
    }

    result = http_call(api_url, headers)

    if not result:
        #log_write(f"api return empty.")
        exit(0)

    if '{' not in result:
        abort("corrupted reply JSON")

    cmd = json.loads(result)

    if ('request_id' not in cmd):
        abort("no request_id in reply JSON")

    if ('app_code' not in cmd):
        abort("no app_code in reply JSON")

    if ('command' not in cmd):
        abort("no command in reply JSON")

    return cmd

def put_result():
    global response

    instance_id = response['instance_id']
    request_id = response['request_id']

    api_url = f"https://deploy.pub-sec.net/api/put_result/{instance_id}/{request_id}"
    #print (f"api_url = {api_url}")

    headers = {
        "Content-Type" : "application/json"
    }
    result = http_call_post(api_url, headers, response)
    return result

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

def http_call_post(url, headers = {}, payload = {}):
    #print (url)
    #print (headers)
    #print (payload)

    headers = {
        "Content-Type" : "application/json"
    }
    method = 'POST'
    params = payload
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

        error_response = json.loads(error_desc)
        status_code = get_key(error_response, 'status_code')
        message = get_key(error_response, 'message')
        log_write (f"SERVER ERROR: {status_code} : {message}")

        return {}


    exit(0)

# キーがなくてもエラーで止まらないように関数を挟んでいます
def get_key(dic, key):
    if (key in dic):
        return str(dic[key])
    else:
        return str('')

def init_response():

    response = {
        'request_id'           : 0,
        'app_code'             : '',
        'instance_id'          : '',
        'command'              : '',
        'options'              : '',
        'message'              : '',
        'success'              : 'N',
        'test_git_revision'    : '',
        'test_last_pull_time'  : '',
        'test_last_commit_time': '',
        'test_last_commit_msg' : '',
        'live_git_revision'    : '',
        'live_last_pull_time'  : '',
        'live_last_commit_time': '',
        'live_last_commit_msg' : ''
    }

    return response

def update_env(app_code):

    # Make hash for authorization
    request_time = int(time.time())
    original = f"{request_time}{API_HASH_SEED}{app_code}".encode('utf8')
    print (f"update_env() original {original}")
    request_hash = hashlib.sha256(original).hexdigest()

    # call deploy api to get latest production env.
    api_url = f"https://deploy.pub-sec.net/api/get_env/{app_code}?rh={request_hash}&rt={request_time}"

    headers = {
        "Content-Type" : "application/json"
    }

    result = http_call(api_url, headers)

    if not result:
        #log_write(f"api return empty.")
        return

    if '{' not in result:
        return

    cmd = json.loads(result)

    if ('success' not in cmd):
        return

    if ('production_env' not in cmd):
        return

    production_env = cmd['production_env']

    # Check if env file contains proper entry

    if ('APP_NAME' not in production_env):
        return

    # backup current env file
    tgt_path = f"/var/www/production/{app_code}/test/.env"

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

if __name__ == "__main__":
    main(sys.argv[1:])
