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
PERMS_SCRIPT=/home/ec2-user/bin/laravel_shared_perms.sh

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

# storage / bootstrap/cache を apache と ec2-user の両方で読み書きできるようにする
set_laravel_perms() {
    if [ -x $PERMS_SCRIPT ]; then
        $PERMS_SCRIPT $1
    else
        touch $1/storage/logs/laravel.log
        chmod -R a+w $1/storage
        chmod -R a+w $1/bootstrap/cache
    fi
}

# サーバの PHP に、Laravel と依存パッケージが対応しているかを確認する（非対応なら 1 を返す）
# 引数: Laravel プロジェクトのディレクトリ
check_php_compat() {
    local dir=$1
    local php_ver=`php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;'`
    local php_id=`php -r 'echo PHP_VERSION_ID;'`

    echo "PHP $php_ver への対応を確認しています..."

    if [ ! -f "$dir/composer.lock" ]; then
        echo "エラー: $dir/composer.lock がないため、PHP $php_ver に対応しているか確認できません"
        return 1
    fi

    # 1. Laravel のバージョン（composer.lock から取得。例: 11.31.0）
    local laravel_ver=`php -r '
        $lock = json_decode(file_get_contents($argv[1]), true);
        foreach (($lock["packages"] ?? []) as $p) {
            if ($p["name"] === "laravel/framework") { echo ltrim($p["version"], "v"); }
        }' -- "$dir/composer.lock"`
    local laravel_major=${laravel_ver%%.*}

    if ! [[ "$laravel_major" =~ ^[0-9]+$ ]]; then
        echo "エラー: composer.lock から Laravel のバージョンを取得できません (laravel/framework: '$laravel_ver')"
        return 1
    fi

    # PHP のバージョンごとに、公式に対応している Laravel の最小メジャーバージョン
    #   PHP 8.4 → Laravel 11 以上 / PHP 8.3 → Laravel 10 以上
    local min_laravel=0
    if [ "$php_id" -ge 80400 ]; then
        min_laravel=11
    elif [ "$php_id" -ge 80300 ]; then
        min_laravel=10
    fi

    if [ "$laravel_major" -lt "$min_laravel" ]; then
        echo "エラー: Laravel $laravel_ver は PHP $php_ver に対応していません（Laravel $min_laravel 以上が必要です）"
        echo "        Laravel をアップグレードしてから、再度実行してください"
        return 1
    fi
    echo "OK: Laravel $laravel_ver"

    # 2. 依存パッケージが要求する PHP バージョン・拡張モジュール（composer.lock をもとに確認）
    if ! (cd "$dir" && composer check-platform-reqs --lock --no-dev); then
        echo "エラー: 依存パッケージが PHP $php_ver / このサーバの拡張モジュールに対応していません（上の failed / missing の行を確認してください）"
        return 1
    fi
    echo "OK: 依存パッケージ"
}

if [ $# -ne 3 ]; then
  echo "これは、新規の本番Laravelプロジェクトをサーバ環境にインストールするスクリプトです。"
  echo "例： ./sykfish_setup.sh git@github.com:mir-ai/t102L-laravel-rd.git t102L-laravel-rd rd.mir-ai.net"
  echo "                       ↑GITコード                                   ↑プロジェクトコード ↑本番URL"
  echo "deploy にプロジェクトコードに対応した .env が設定されている必要があります"
  exit 1
fi

GITNAME=$1
BASENAME=$2
DOMAIN=$3

DIR=$BASEDIR$BASENAME

# 中止時に $DIR を削除するので、プロジェクトコードが空や / を含む場合は受け付けない
if [ -z "$BASENAME" ] || [[ "$BASENAME" == */* ]] || [[ "$BASENAME" == .* ]]; then
    echo "エラー: プロジェクトコード '$BASENAME' が不正です"
    exit 1
fi

if [ -d $DIR ]; then
    echo "エラー: すでに $DIR ディレクトリが存在しています"
    exit
fi

GIT_SSH="$GITNAME"

echo "GITコード: $GITNAME"
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
if [ ! -d sky ]; then
    cd $BASEDIR && rm -rf "$DIR"
    echo "エラー: git clone に失敗しました。中止します（$DIR は削除しました）"
    exit 1
fi
cd sky

# .env の取得や composer install の前に、PHP のバージョンへの対応を確認する
if ! check_php_compat .; then
    cd $BASEDIR && rm -rf "$DIR"
    echo
    echo "中止しました（作成途中の $DIR は削除しました）"
    exit 1
fi

if ! /home/ec2-user/bin/skyfish_setup_env.py $BASENAME; then
    cd $BASEDIR && rm -rf "$DIR"
    echo
    echo "エラー: deploy から .env を取得できませんでした（sky）。中止します（作成途中の $DIR は削除しました）"
    exit 1
fi

if ! composer install --no-dev --optimize-autoloader; then
    cd $BASEDIR && rm -rf "$DIR"
    echo
    echo "エラー: composer install に失敗しました（sky）。中止します（作成途中の $DIR は削除しました）"
    exit 1
fi
set_laravel_perms .
git pull
cd -

git clone $GIT_SSH fish
if [ ! -d fish ]; then
    cd $BASEDIR && rm -rf "$DIR"
    echo "エラー: git clone に失敗しました（fish）。中止します（$DIR は削除しました）"
    exit 1
fi
cd fish
if ! /home/ec2-user/bin/skyfish_setup_env.py $BASENAME; then
    cd $BASEDIR && rm -rf "$DIR"
    echo
    echo "エラー: deploy から .env を取得できませんでした（fish）。中止します（作成途中の $DIR は削除しました）"
    exit 1
fi

if ! composer install --no-dev --optimize-autoloader; then
    cd $BASEDIR && rm -rf "$DIR"
    echo
    echo "エラー: composer install に失敗しました（fish）。中止します（作成途中の $DIR は削除しました）"
    exit 1
fi
set_laravel_perms .
git pull
cd -

ln -s sky live
ln -s fish test

# vhost

STAGE=live
curl -fo vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf_live.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

STAGE=test
curl -fo vhost.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_conf_test.txt
$SED -i "s/DOMAIN/$DOMAIN/" vhost.conf
$SED -i "s/BASENAME/$BASENAME/" vhost.conf
sudo mv vhost.conf $HTTPD_CONF_DIR/vhost-$BASENAME-$STAGE.conf
echo "> $HTTPD_CONF_DIR/$BASENAME-$STAGE.conf"

DOMAIN_TEST="test-$DOMAIN"

# supervisord / queue worker
curl -fo supervisor.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_supervisord_confd_conf.txt
$SED -i "s/BASENAME/$BASENAME/" supervisor.conf
sudo mv supervisor.conf /etc/supervisord/conf.d/$BASENAME.conf
echo "> /etc/supervisord/conf.d/$BASENAME.conf"

# systemd / system
# 無効化: 雛形の ExecStart (/home/ec2-user/bin/mir-<プロジェクトコード>.py) に対応するスクリプトが無く、
#         有効にすると毎分失敗するタイマーができるため。プロジェクト専用のタイマーが必要になったら、
#         ~/bin/etc_sytemd_system_BASENAME_*.txt を元に手動で作成する。
#curl -fo systemd.timer https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_sytemd_system_BASENAME_timer.txt
#$SED -i "s/BASENAME/mir-$BASENAME/g" systemd.timer
#sudo mv systemd.timer /etc/systemd/system/mir-$BASENAME.timer
#echo "> /etc/systemd/system/mir-$BASENAME.timer"
#
#curl -fo systemd.service https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_sytemd_system_BASENAME_service.txt
#$SED -i "s/BASENAME/mir-$BASENAME/g" systemd.service
#sudo mv systemd.service /etc/systemd/system/mir-$BASENAME.service
#echo "> /etc/systemd/system/mir-$BASENAME.service"
#
#sudo chown root /etc/systemd/system/mir-$BASENAME.*
#sudo chgrp root /etc/systemd/system/mir-$BASENAME.*
#
#sudo systemctl daemon-reload
#sudo systemctl enable --now mir-$BASENAME.timer
#systemctl list-timers

# mysql
DB_HOST=`grep DB_HOST= $DIR/live/.env | cut -d = -f 2`
DB_DATABASE=`grep DB_DATABASE= $DIR/live/.env | cut -d = -f 2`
DB_USERNAME=`grep DB_USERNAME= $DIR/live/.env | cut -d = -f 2`
DB_PASSWORD=`grep DB_PASSWORD= $DIR/live/.env | cut -d = -f 2`

# git first pull
cd $DIR/live; git pull
cd -
cd $DIR/test; git pull
cd -

# permission
set_laravel_perms $DIR/live
set_laravel_perms $DIR/test


echo "[mysql]"
echo "DB_HOST     : $DB_HOST"
echo "DB_DATABASE : $DB_DATABASE"
echo "DB_USERNAME : $DB_USERNAME"
echo "DB_PASSWORD : $DB_PASSWORD"
echo
echo "[migration]"
echo "php artisan migrate"
echo
echo "[/etc/hosts]"
echo "127.0.0.1   loopback-$DOMAIN"
echo "127.0.0.1   loopback-test-$DOMAIN"
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
#echo "[crontab]"
#echo "sudo -u apache crontab -e"
#echo "* * * * * sleep 1 && cd $DIR/live && php artisan schedule:run >> /dev/null 2>&1"
echo "[supervisord / queue]"
echo "cat /etc/supervisord/conf.d/$BASENAME.conf"
echo "sudo /usr/local/bin/supervisorctl status"
echo "sudo /usr/local/bin/supervisorctl update"
echo "sudo /usr/local/bin/supervisorctl status"
