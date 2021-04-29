#!/bin/bash

# Skyfish setup
# 
# Script to newly setup laravel production

# Susumu Obata
# Created: 2020/9/18
# Updated: 2021/4/29

echo "----------------------------"
echo "Skyfish setup"
echo "----------------------------"
echo

BASEDIR=/var/www/production/
HTTPD_CONF_DIR=/etc/httpd/conf.d
EXEC_USER=ec2-user
SED=sed
PWD=`pwd`

if [ -d /Users/obatasusumu ]; then
    BASEDIR=/Users/obatasusumu/tmp/skyfish/
    HTTPD_CONF_DIR=/tmp
    EXEC_USER=obatasusumu
    SED=gsed
fi

if [ ! `whoami` = $EXEC_USER ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit
fi

if [ $# -ne 2 ]; then
  echo "これは、新規の本番Laravelプロジェクトをサーバ環境にインストールするスクリプトです。"
  echo "例： ./sykfish_setup.sh 180L-mir-mms-isehara-v1 mms-isehara.cityj.net"
  echo "                       ↑プロジェクトコード         ↑本番URL"
  echo "deploy に .env が設定されている必要があります"
  exit 1
fi

BASENAME=$1
DOMAIN=$2

DIR=$BASEDIR$BASENAME

if [ -d $DIR ]; then
    echo "エラー: すでに $DIR ディレクトリが存在しています"
    exit
fi

GIT_SSH="git@github.com:mir-aie/$BASENAME.git"

echo "プロジェクトコード: $BASENAME"
echo "Webアクセスドメイン: $DOMAIN"
echo "gitリポジトリ: $GIT_SSH"
echo "で作成します。"
echo
echo "deploy の .env を参照します"

sleep 5

sudo mkdir -p $DIR
sudo chown $EXEC_USER $DIR
cd $DIR

git clone $GIT_SSH sky
cd sky
composer install --no-dev --optimize-autoloader
touch storage/logs/laravel.log
sudo chown ec2-user storage/logs/laravel.log
sudo chgrp ec2-user storage/logs/laravel.log
chmod -R a+w storage
chmod -R a+w bootstrap/cache
/home/ec2-user/bin/skyfish_setup_env.py $BASENAME
cd -

git clone $GIT_SSH fish
cd fish
composer install --no-dev --optimize-autoloader
touch storage/logs/laravel.log
sudo chown ec2-user storage/logs/laravel.log
sudo chgrp ec2-user storage/logs/laravel.log
chmod -R a+w storage
chmod -R a+w bootstrap/cache
/home/ec2-user/bin/skyfish_setup_env.py $BASENAME
cd -

ln -s sky live
ln -s fish test

# vhost

STAGE=live
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf_live.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

STAGE=test
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf_test.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

DOMAIN_TEST="test-$DOMAIN"

# supervisord / queue worker
curl -o supervisor.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_suprevisord_confd_conf.txt
$SED -i "s/BASENAME/$BASENAME/" supervisor.conf
sudo mv supervisor.conf /etc/supervisord/conf.d/$BASENAME.conf
echo "> /etc/supervisord/conf.d/$BASENAME.conf"

# mysql
DB_HOST=`grep DB_HOST= $DIR/live/.env | cut -d = -f 2`
DB_DATABASE=`grep DB_DATABASE= $DIR/live/.env | cut -d = -f 2`
DB_USERNAME=`grep DB_USERNAME= $DIR/live/.env | cut -d = -f 2`
DB_PASSWORD=`grep DB_PASSWORD= $DIR/live/.env | cut -d = -f 2`

echo "[mysql]"
echo "DB_HOST     : $DB_HOST"
echo "DB_DATABASE : $DB_DATABASE"
echo "DB_USERNAME : $DB_USERNAME"
echo
echo "[migration]"
echo "php artisan migrate"
echo
echo "[permission]"
echo "chmod -R a+w $DIR/storage"
echo "chmod -R a+w $DIR/bootstrap/cache"
echo
echo "[/etc/hosts]"
echo "127.0.0.1   loopback-$DOMAIN"
echo "127.0.0.1   test-loopback-$DOMAIN"
echo
echo "[Route 53]"
echo "$DOMAIN"
echo "test-$DOMAIN"
echo
echo "[vhost]"
echo "cd /etc/httpd/conf.d/"
echo "cat $HTTPD_CONF_DIR/vhost-$BASENAME-live.conf"
echo "cat $HTTPD_CONF_DIR/vhost-$BASENAME-test.conf"
echo "sudo service httpd configtest"
echo "sudo service httpd graceful"
echo
echo "[crontab]"
echo "* * * * * /usr/bin/php $DIR/live/artisan schedule:run >> /dev/null 2>&1"
echo 
echo "[supervisord / queue]"
echo "cat /etc/supervisord/conf.d/$BASENAME.conf"
