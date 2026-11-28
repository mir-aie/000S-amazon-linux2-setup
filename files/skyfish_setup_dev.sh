#!/bin/bash
#
# Skyfish setup dev
#
# 検証環境の EC2 サーバに、新しい Laravel プロジェクトを設置するスクリプト
#   - 設置場所: /var/www/dev/<プロジェクトコード>
#   - .env は設置しない（実行後に手で設置する）
#   - httpd の vhost / supervisor / systemd timer のファイルを設置する
#   - httpd の再読込み・supervisorctl・timer の有効化は行わず、実行するコマンドを最後に表示する
#
# 本番環境用は skyfish_setup_production.sh
#
# Susumu Obata
# Created: 2022/6/18

echo "----------------------------"
echo "Skyfish setup dev"
echo "----------------------------"
echo

BASEDIR=/var/www/dev
HTTPD_CONF_DIR=/etc/httpd/conf.d
SUPERVISOR_CONF_DIR=/etc/supervisord/conf.d
SYSTEMD_DIR=/etc/systemd/system
EXEC_USER=ec2-user
SED="sed"
SUDO=sudo
PERMS_SCRIPT=/home/ec2-user/bin/laravel_shared_perms.sh
TEMPLATE_URL=https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files

# 手元の Mac で試すとき
if [ -d /Users/obatasusumu ]; then
    BASEDIR=/Users/obatasusumu/tmp/skyfish/dev
    HTTPD_CONF_DIR=/tmp/skyfish/httpd
    SUPERVISOR_CONF_DIR=/tmp/skyfish/supervisord
    SYSTEMD_DIR=/tmp/skyfish/systemd
    EXEC_USER=obatasusumu
    SED=gsed
    SUDO=
    mkdir -p $BASEDIR $HTTPD_CONF_DIR $SUPERVISOR_CONF_DIR $SYSTEMD_DIR
fi

if [ "$(whoami)" != "$EXEC_USER" ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit 1
fi

if [ $# -ne 3 ]; then
    echo "これは、新規の検証用 Laravel プロジェクトを $BASEDIR に設置するスクリプトです。"
    echo
    echo "例： ./skyfish_setup_dev.sh 300L-00-core-alert-v3 300L-miraie-999999-alert-v3 check-miraie.a-alert.net"
    echo "                            ↑GITコード            ↑プロジェクトコード         ↑検証用URL"
    echo
    echo "GITコードは git@github.com:mir-aie/xxx.git のように URL で指定することもできます"
    exit 1
fi

GITNAME=$1
BASENAME=$2
DOMAIN=$3

# GITコードがリポジトリ名だけなら mir-aie のリポジトリとみなす
if [[ "$GITNAME" == *:* ]] || [[ "$GITNAME" == */* ]]; then
    GIT_SSH=$GITNAME
else
    GIT_SSH="git@github.com:mir-aie/$GITNAME.git"
fi

# 中止時に $DIR を削除し、sed の置換にも使うので、英数字と . _ - 以外は受け付けない
if ! [[ "$BASENAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo "エラー: プロジェクトコード '$BASENAME' が不正です"
    exit 1
fi
if ! [[ "$DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
    echo "エラー: ドメイン '$DOMAIN' が不正です"
    exit 1
fi

DIR=$BASEDIR/$BASENAME
VHOST_CONF=$HTTPD_CONF_DIR/vhost-$BASENAME-check.conf
SUPERVISOR_CONF=$SUPERVISOR_CONF_DIR/$BASENAME.conf
UNIT=mir-$BASENAME
SERVICE_FILE=$SYSTEMD_DIR/$UNIT.service
TIMER_FILE=$SYSTEMD_DIR/$UNIT.timer

# 既存のプロジェクトを上書きしないよう、作る予定のファイルが1つでもあれば中止する
for f in $DIR $VHOST_CONF $SUPERVISOR_CONF $SERVICE_FILE $TIMER_FILE; do
    if [ -e "$f" ]; then
        echo "エラー: すでに $f が存在しています"
        exit 1
    fi
done

# サーバの PHP に、Laravel と依存パッケージが対応しているかを確認する（非対応なら 1 を返す）
# 引数: Laravel プロジェクトのディレクトリ
check_php_compat() {
    local dir=$1
    local php_ver php_id laravel_ver laravel_major min_laravel
    php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    php_id=$(php -r 'echo PHP_VERSION_ID;')

    echo "PHP $php_ver への対応を確認しています..."

    if [ ! -f "$dir/composer.lock" ]; then
        echo "エラー: $dir/composer.lock がないため、PHP $php_ver に対応しているか確認できません"
        return 1
    fi

    # 1. Laravel のバージョン（composer.lock から取得。例: 11.31.0）
    laravel_ver=$(php -r '
        $lock = json_decode(file_get_contents($argv[1]), true);
        foreach (($lock["packages"] ?? []) as $p) {
            if ($p["name"] === "laravel/framework") { echo ltrim($p["version"], "v"); }
        }' -- "$dir/composer.lock")
    laravel_major=${laravel_ver%%.*}

    if ! [[ "$laravel_major" =~ ^[0-9]+$ ]]; then
        echo "エラー: composer.lock から Laravel のバージョンを取得できません (laravel/framework: '$laravel_ver')"
        return 1
    fi

    # PHP のバージョンごとに、公式に対応している Laravel の最小メジャーバージョン
    #   PHP 8.4 → Laravel 11 以上 / PHP 8.3 → Laravel 10 以上
    min_laravel=0
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

# 作成途中の $DIR を削除して中止する
abort() {
    cd "$BASEDIR" && rm -rf "$DIR"
    echo
    echo "エラー: $1"
    echo "中止しました（作成途中の $DIR は削除しました）"
    exit 1
}

echo "GITコード        : $GITNAME"
echo "gitリポジトリ    : $GIT_SSH"
echo "プロジェクトコード: $BASENAME"
echo "検証用URL        : $DOMAIN"
echo "設置場所         : $DIR"
echo "で作成します。中止する場合は 5 秒以内に Ctrl-C を押してください。"
echo

sleep 5

# 1. 雛形を先にすべて取得する（途中で失敗して中途半端に設置されないように）
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for t in etc_httpd_confd_vhost_conf_check etc_supervisord_confd_conf_check \
         etc_sytemd_system_BASENAME_service etc_sytemd_system_BASENAME_timer; do
    if ! curl -fsS -o "$TMP/$t.txt" "$TEMPLATE_URL/$t.txt"; then
        echo "エラー: 雛形 $t.txt を取得できませんでした。中止します"
        exit 1
    fi
done

# 2. プロジェクトを設置する
# /var/www/dev は ec2-user:apache 2775 なので sudo は不要（配下は apache グループを引き継ぐ）
if ! git clone "$GIT_SSH" "$DIR"; then
    abort "git clone に失敗しました"
fi
cd "$DIR" || abort "$DIR に移動できません"

# composer install の前に、PHP のバージョンへの対応を確認する
check_php_compat . || abort "PHP のバージョンに対応していません"

composer install --no-dev --optimize-autoloader || abort "composer install に失敗しました"

if [ -x $PERMS_SCRIPT ]; then
    $PERMS_SCRIPT "$DIR" || abort "$PERMS_SCRIPT に失敗しました"
else
    echo "警告: $PERMS_SCRIPT がないため、storage のパーミッションを設定していません"
fi

# 3. vhost / supervisor / systemd のファイルを設置する
# 雛形は本番用のパスで書かれているものがあるので、検証環境のパスに置き換える
cd "$TMP" || exit 1

$SED -i -e "s/DOMAIN/$DOMAIN/g" -e "s/BASENAME/$BASENAME/g" etc_httpd_confd_vhost_conf_check.txt
$SED -i -e "s/BASENAME/$BASENAME/g" etc_supervisord_confd_conf_check.txt
for f in etc_sytemd_system_BASENAME_service.txt etc_sytemd_system_BASENAME_timer.txt; do
    $SED -i -e "s#/var/www/production/BASENAME/live/#$DIR/#g" -e "s/BASENAME/$BASENAME/g" $f
done

if grep -q /var/www/production etc_sytemd_system_BASENAME_service.txt; then
    echo "警告: $SERVICE_FILE に本番のパス (/var/www/production) が残っています。確認してください"
fi

$SUDO install -m 0644 etc_httpd_confd_vhost_conf_check.txt "$VHOST_CONF"
$SUDO install -m 0644 etc_supervisord_confd_conf_check.txt "$SUPERVISOR_CONF"
$SUDO install -m 0644 etc_sytemd_system_BASENAME_service.txt "$SERVICE_FILE"
$SUDO install -m 0644 etc_sytemd_system_BASENAME_timer.txt "$TIMER_FILE"

echo
echo "設置しました:"
echo "  $DIR"
echo "  $VHOST_CONF"
echo "  $SUPERVISOR_CONF"
echo "  $SERVICE_FILE"
echo "  $TIMER_FILE"

# 4. 残りの作業（コマンドの表示だけで、実行はしない）
cat <<EOF

========================================================
以下は手で実行してください
========================================================

[1. .env]
vi $DIR/.env
cd $DIR
php artisan key:generate        # APP_KEY が空の場合のみ

[2. mysql]
# RDS にマスターユーザーで接続する（ローカルの MariaDB なら sudo mysql）
mysql -u <RDSのマスターユーザー> -p -h <RDSのエンドポイント>
create database DATABASE_NAME default charset utf8mb4;
create user '${BASENAME}_stg_user'@'%' identified by '${BASENAME}_stg_pass_XXXX';
grant all on DATABASE_NAME.* to '${BASENAME}_stg_user'@'%';

[3. migration / キャッシュ]
cd $DIR
php artisan migrate
php artisan optimize
$PERMS_SCRIPT $DIR

[4. Route 53 / /etc/hosts]
$DOMAIN を、このサーバに向ける
sudo sh -c 'echo "127.0.0.1   loopback-$DOMAIN" >> /etc/hosts'

[5. httpd]
cat $VHOST_CONF
sudo apachectl configtest
sudo systemctl reload httpd

[6. supervisor / queue worker]
# 雛形はコメントアウトされているので、queue を使う場合は # を外す
sudo vi $SUPERVISOR_CONF
sudo /usr/local/bin/supervisorctl update
sudo /usr/local/bin/supervisorctl status

[7. timer (schedule:run を毎分実行)]
# .env を置いてから有効にする（.env がないと毎分失敗する）
cat $SERVICE_FILE
cat $TIMER_FILE
sudo systemd-analyze verify $SYSTEMD_DIR/$UNIT.*
sudo systemctl daemon-reload
sudo systemctl enable --now $UNIT.timer
systemctl list-timers $UNIT.timer
journalctl -n 50 -u $UNIT.service

[Web]
http://$DOMAIN/
EOF
