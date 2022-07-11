#!/bin/bash

# Skyfish install check app
# 
# Script to newly setup laravel staging

# Susumu Obata
# Created: 2022/6/18

echo "----------------------------"
echo "Skyfish setup stage"
echo "----------------------------"
echo

BASEDIR=/var/www/dev/
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

if [ $# -ne 3 ]; then
  echo "これは、新規の試験用Laravelプロジェクトをサーバ環境にインストールするスクリプトです。"
  echo "例： ./skyfish_setup_stage.sh 300L-00-core-alert-v3 300L-miraie-999999-alert-v3 check-miraie.a-alert.net"
  echo "                                   ↑GITコード             ↑プロジェクトコード             ↑チェック用URL"
  exit 1
fi

GITNAME=$1
BASENAME=$2
DOMAIN=$3

DIR=$BASEDIR$BASENAME

if [ -d $DIR ]; then
    echo "エラー: すでに $DIR ディレクトリが存在しています"
    exit
fi

GIT_SSH="git@github.com:mir-aie/$GITNAME.git"

echo "GITコード: $GITNAME"
echo "プロジェクトコード: $BASENAME"
echo "Webアクセスドメイン: $DOMAIN"
echo "gitリポジトリ: $GIT_SSH"
echo "で作成します。"
echo

sleep 5

sudo mkdir -p $DIR
sudo chown $EXEC_USER $DIR
cd $BASEDIR

git clone $GIT_SSH $BASENAME
cd $BASENAME
composer install --no-dev --optimize-autoloader
touch storage/logs/laravel.log
sudo chown ec2-user storage/logs/laravel.log
sudo chgrp ec2-user storage/logs/laravel.log
sudo mkdir storage/app/mir_tmp
sudo chown ec2-user storage/app/mir_tmp
sudo chgrp ec2-user storage/app/mir_tmp
chmod -R a+w storage
chmod -R a+w bootstrap/cache
cd $DIR

# vhost

curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf_check.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-check.conf
echo "> $HTTPD_CONF_DIR/vhost-$BASENAME-check.conf"

# supervisord / queue worker
curl -o supervisor.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_suprevisord_confd_conf_check.txt
$SED -i "s/BASENAME/$BASENAME/" supervisor.conf
sudo mv supervisor.conf /etc/supervisord/conf.d/$BASENAME.conf
echo "> /etc/supervisord/conf.d/$BASENAME.conf"

echo "[.env]"
echo "vi $DIR/.env"
echo 
echo "cd $DIR"

# mysql
echo `grep DB_HOST= $DIR/.env | cut -d = -f 2`
echo `grep DB_DATABASE= $DIR/.env | cut -d = -f 2`
echo `grep DB_USERNAME= $DIR/.env | cut -d = -f 2`
echo `grep DB_PASSWORD= $DIR/.env | cut -d = -f 2`

DB_HOST=localhost
DB_DATABASE="DATABASE_NAME"
DB_USERNAME="DATABASE_USER"
DB_PASSWORD="DATABASE_PASS"

echo "[mysql]"
echo "mysql -u $DB_USERNAME -p"
echo "$DB_PASSWORD"
echo "create database $DB_DATABASE default charset utf8mb4;"
echo
echo "[migration]"
echo "php artisan migrate"
echo "php artisan db:seed --class=UserTableSeeder"
echo
echo "[permission]"
echo "chmod -R a+w $DIR/storage"
echo "chmod -R a+w $DIR/bootstrap/cache"
echo
echo "[Route 53]"
echo "$DOMAIN"
echo "test-$DOMAIN"
echo
echo "[vhost]"
echo "cat $HTTPD_CONF_DIR/vhost-$BASENAME-check.conf"
echo "sudo service httpd configtest"
echo "sudo service httpd graceful"
echo
echo "[crontab]"
echo "sudo crontab -u apache -e"
echo "* * * * * /usr/bin/php $DIR/artisan schedule:run >> /dev/null 2>&1"
echo 
echo "[supervisord / queue]"
echo "cat /etc/supervisord/conf.d/$BASENAME.conf"
echo "sudo /usr/local/bin/supervisorctl status"
echo "sudo /usr/local/bin/supervisorctl reload"
echo "sudo /usr/local/bin/supervisorctl status"
echo 
echo "[Web]"
echo $DOMAIN


