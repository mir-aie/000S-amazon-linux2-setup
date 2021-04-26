#!/bin/bash

PATH=$PATH:/usr/local/bin

cd /home/ec2-user/mecab

./mecab-ipadic-neologd/bin/install-mecab-ipadic-neologd -n -y -u -p /home/ec2-user/mecab/dic/mecab-ipadic-neologd > cron-update.log 2>
&1
