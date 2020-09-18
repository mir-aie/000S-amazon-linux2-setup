#!/bin/bash

# Susumu Obata
# 2020/9/18
#

echo "----------------------------"
echo "Skyfish update staging"
echo "----------------------------"
echo

BASEDIR=/var/www/production
EXEC_USER=ec2-user
PWD=`pwd`

BASEDIR=/Users/obatasusumu/tmp/skyfish
EXEC_USER=obatasusumu

if [ ! `whoami` = $EXEC_USER ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit
fi

if [ ! `pwd | grep $BASEDIR` ]; then
        echo "エラー: $BASEDIR のプロジェクトディレクトリで実行してください(1)。"
        echo "例: cd $BASEDIR/012L-sky-fish"
        exit
fi

if [ ! -f staging/composer.json ]; then
    echo "エラー: $BASEDIR のプロジェクトディレクトリで実行してください(2)。"
    echo "例: cd $BASEDIR/012L-sky-fish"
    exit
fi

cd staging

PWDP=`pwd -P`
CURRENT=`basename $PWDP`
echo $CURRENT
if [ $CURRENT = 'fish' ]; then
    echo "「FISH。それは、さかな」 を更新しています。https://stage-*.***.** でご確認ください"
else
    echo "「SKY。それは、そら」 を更新しています。https://stage-*.***.** でご確認ください"
fi


echo "git pull"
git pull

read -p "composer install を実行しますか？ (y/N): " yn
if [ "`echo $yn | grep -i Y`" ]; then
    composer install
else
    read -p "composer dump-autoload を実行しますか？ (y/N): " yn
    if [ "`echo $yn | grep -i Y`" ]; then
        composer dump-autoload
    fi
fi

read -p "php artisan optimize系 を実行しますか？ (y/N): " yn
if [ "`echo $yn | grep -i Y`" ]; then
    php artisan config:cache
    php artisan route:cache
fi

read -p "queue を再起動しますか？ (y/N): " yn
if [ "`echo $yn | grep -i Y`" ]; then
    sudo systemctl restart supervisord
fi

cd -
