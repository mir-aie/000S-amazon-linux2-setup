#!/bin/bash

# Susumu Obata
# 2021/1/12
#

echo "----------------------------"
echo "Skyfish setup vhost"
echo "----------------------------"
echo

HTTPD_CONF_DIR=/etc/httpd/conf.d
EXEC_USER=ec2-user
SED=sed
PWD=`pwd`

if [ $# -ne 3 ]; then
  echo "usage: $0 BASENAME DOMAIN" 1>&2
  echo "ex: $0 163L-mir-proc-v1 proc.hamamatsu.odpf.net" 1>&2
  exit 1
fi

if [ -d /Users/obatasusumu ]; then
    HTTPD_CONF_DIR=/tmp
    EXEC_USER=obatasusumu
    SED=gsed
fi

if [ ! `whoami` = $EXEC_USER ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit
fi

BASENAME=$1
BASENAME=$2

echo "プロジェクトコード: $BASENAME"
echo "Webアクセスドメイン: $DOMAIN"
read -p "よろしいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

STAGE=live
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
$SED -i "s/STAGE/$STAGE/" vhost.conf
$SED -i "s/ServerAlias /ServerAlias loopback-/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

STAGE=test
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
$SED -i "s/STAGE/$STAGE/" vhost.conf
$SED -i "s/www\./test\./" vhost.conf
$SED -i "s/ServerAlias /ServerAlias loopback-/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"
