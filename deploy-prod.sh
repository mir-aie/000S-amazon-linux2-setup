#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

# New
DEPLOY_DIR=137-2020-07-23-2
TARGET_DIR=137L-ping-v1

cd /var/www/production
mkdir lara-$TARGET_DIR
mv $TARGET_DIR lara-$TARGET_DIR/$DEPLOY_DIR
cd lara-$TARGET_DIR
ln -s $DEPLOY_DIR staging
mkdir storage
chmod a+w storage

#ln -s $DEPLOY_DIR live


# UPDATE
DEPLOY_DIR=137-2020-07-23-2
TARGET_DIR=137L-ping-v1

cd /var/www/production
mv $TARGET_DIR lara-$TARGET_DIR/$DEPLOY_DIR
cd lara-$TARGET_DIR
ln -nfs $DEPLOY_DIR staging
cp live/.env staging/.env


