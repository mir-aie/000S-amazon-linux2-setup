#!/bin/bash

PATH=$PATH:/usr/local/bin

cd /home/ec2-user/mecab-ipadic-neologd

date >> cron-update.log
./bin/install-mecab-ipadic-neologd -n -y >> cron-update.log 2 >&1
date >> cron-update.log
