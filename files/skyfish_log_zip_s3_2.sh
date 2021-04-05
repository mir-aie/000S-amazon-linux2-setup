#!/bin/bash

# Susumu Obata
# 2021/4/4
#

# add crontab
# 0 4 5 * * /home/ec2-user/bin/skyfish_log_zip_s3.sh >> /tmp/skyfish_log_zip_s3.txt 2>&1

echo "----------------------------"
echo "Skyfish Log Zip S3"
echo
echo "Zip logs and go S3"
echo "----------------------------"
echo

cd /home/ec2-user/log/httpd
YYYY_MM=`date '+%Y-%m' -d 'last month'`
YYYYMM=`date '+%Y%m' -d 'last month'`
ZIP_FILE=$YYYY_MM-hama-odpf-httpd-log.zip
ZIP_PASSWORD=odpf$YYYYMM
S3_PREFIX=https://ss-pubsec-logs.s3-ap-northeast-1.amazonaws.com/221309-hamamatsu/

CMD="zip -P $ZIP_PASSWORD -r $ZIP_FILE $YYYY_MM/*-hmpf-*"
echo $CMD
$CMD

CMD="aws s3 cp $ZIP_FILE s3://ss-pubsec-logs/221309-hamamatsu/ --acl public-read --profile log_upload_s3 --region ap-northeast-1"
echo $CMD
$CMD

rm $ZIP_FILE

DOWNLOAD_URL=$S3_PREFIX$ZIP_FILE
aws sns publish --topic-arn arn:aws:sns:ap-northeast-1:360491754249:pubsec-log-archive --message "Log archive ready: $DOWNLOAD_URL" --profile log_upload_s3 --region ap-northeast-1
