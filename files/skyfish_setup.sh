#!/bin/bash

# Susumu Obata
# 2020/9/18
#

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

read -p "skyfish 環境を初期セットアップします？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

read -p "プロジェクトコードはなんですか (例: 012L-sky-fish): " BASENAME
read -p "'$BASENAME' で間違いないですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

DIR=$BASEDIR$BASENAME

if [ -d $DIR ]; then
    echo "エラー: すでに $DIR ディレクトリが存在しています"
    exit
fi

read -p "webアクセス用のドメインはなんですか(例: www.mir-ai.net): " DOMAIN
read -p "'$DOMAIN' で間違いないですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

GIT_SSH="git@github.com:mir-aie/$BASENAME.git"
read -p "gitリポジトリは $GIT_SSH でよいですか？ (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "abort." ; exit ;; esac

sudo mkdir -p $DIR
sudo chown $EXEC_USER $DIR
cd $DIR

git clone $GIT_SSH sky
cd sky
composer install --no-dev --optimize-autoloader
touch storage/logs/laravel.log
chmod -R a+w storage
chmod -R a+w bootstrap/cache
./skyfish_setup_env.py $BASENAME
cd -

git clone $GIT_SSH fish
cd fish
composer install --no-dev --optimize-autoloader
touch storage/logs/laravel.log
chmod -R a+w storage
chmod -R a+w bootstrap/cache
./skyfish_setup_env.py $BASENAME
cd -

ln -s sky live
ln -s fish test

STAGE=live
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
$SED -i "s/STAGE/$STAGE/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

STAGE=test
curl -o vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
$SED -i "s/STAGE/$STAGE/" vhost.conf
$SED -i "s/www\./test\./" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

DOMAIN_TEST="test-$DOMAIN"

echo ".env を作成してください"
echo "$DOMAIN を作成してください"
echo "$DOMAIN_TEST を作成してください"
echo "sudo service httpd configtest を実行してください"
echo "sudo service httpd restart を実行してください"
echo "crontab を設定してください"
