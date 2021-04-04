#!/bin/bash

# Susumu Obata
# 2021/4/4
#

# add crontab
# 0 3 5 * * sudo /home/ec2-user/bin/skyfish_log_uploader.sh >> /tmp/skyfish_log_uploader.txt 2>&1

echo "----------------------------"
echo "Skyfish Log Uploader"
echo
echo "scp last month access logs to pubsec prd-pubsec-log-uploader server"
echo "----------------------------"
echo

# Get my host nickname in NICKNAME
source /etc/profile.d/prompt.sh

YYYY_MM=`date '+%Y-%m' -d 'last month'`
YYYYMM=`date '+%Y%m' -d 'last month'`

PWD=`pwd`
EXEC_USER=ec2-user
REMOTE_IP=13.114.120.206
REMOTE_PEM=/home/ec2-user/.credentials/keypair-ss-pubsec-log-uploader.pem
REMOTE_USER=ec2-user
REMOTE_DIR_BASE=/home/ec2-user/log/httpd

#echo $YYYY_MM
#echo $YYYYMM

# wait 1-30 sec (not to access at once from multiple servers)
WAIT_SEC=$(($RANDOM % 30))
echo "sleep $WAIT_SEC"
sleep $WAIT_SEC

# mkdir
REMOTE_DIR=$REMOTE_DIR_BASE/$YYYY_MM/$NICKNAME/
MKDIR_CMD="mkdir -p $REMOTE_DIR"
ssh -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IP $MKDIR_CMD
echo "ssh -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IP $MKDIR_CMD"

# file upload
echo "scp -i $REMOTE_PEM /var/log/httpd/*$YYYY_MM* $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
scp -i $REMOTE_PEM /var/log/httpd/*$YYYY_MM* $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR

echo "scp -i $REMOTE_PEM /var/log/httpd/*$YYYYMM* $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR"
scp -i $REMOTE_PEM /var/log/httpd/*$YYYYMM* $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR

