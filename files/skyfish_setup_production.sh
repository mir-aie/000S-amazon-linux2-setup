#!/bin/bash
#
# Skyfish setup production
#
# 本番環境の EC2 サーバに、新しい Laravel プロジェクトを設置するスクリプト
#   - 設置場所: /var/www/production/<アプリコード>/sky (live) と fish (test) の2か所
#   - .env は deploy (https://deploy.pub-sec.net/) から取得する（skyfish_setup_env.py）
#   - httpd の vhost (live / test) / supervisor / systemd timer のファイルを設置し、timer を有効にする
#   - httpd の再読込み・supervisorctl は行わず、実行するコマンドを最後に表示する
#
# 検証環境用は skyfish_setup_dev.sh
#
# Susumu Obata
# Created: 2020/9/18
# Updated: 2021/4/29

echo "----------------------------"
echo "Skyfish setup production"
echo "----------------------------"
echo

BASEDIR=/var/www/production
HTTPD_CONF_DIR=/etc/httpd/conf.d
SUPERVISOR_CONF_DIR=/etc/supervisord/conf.d
SYSTEMD_DIR=/etc/systemd/system
EXEC_USER=ec2-user
SED="sed"
SUDO=sudo
SYSTEMCTL=systemctl
PERMS_SCRIPT=/home/ec2-user/bin/laravel_shared_perms.sh
SETUP_ENV=/home/ec2-user/bin/skyfish_setup_env.py
TEMPLATE_URL=https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files

# 手元の Mac で試すとき（systemctl は実行せず表示だけ）
if [ -d /Users/obatasusumu ]; then
    BASEDIR=/Users/obatasusumu/tmp/skyfish/production
    HTTPD_CONF_DIR=/tmp/skyfish/httpd
    SUPERVISOR_CONF_DIR=/tmp/skyfish/supervisord
    SYSTEMD_DIR=/tmp/skyfish/systemd
    EXEC_USER=obatasusumu
    SED=gsed
    SUDO=
    SYSTEMCTL="echo systemctl"
    mkdir -p $BASEDIR $HTTPD_CONF_DIR $SUPERVISOR_CONF_DIR $SYSTEMD_DIR
fi

if [ "$(whoami)" != "$EXEC_USER" ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit 1
fi

if [ $# -ne 3 ]; then
    echo "これは、新規の本番 Laravel プロジェクトを $BASEDIR に設置するスクリプトです。"
    echo
    echo "例： ./skyfish_setup_production.sh git@github.com:mir-aie/t102L-laravel-rd.git t102L-laravel-rd rd.mir-ai.net"
    echo "                                   ↑GITコード                                  ↑アプリコード ↑本番URL"
    echo
    echo "GITコードはリポジトリ名だけ (t102L-laravel-rd) でも指定できます（mir-aie のリポジトリとみなします）"
    echo "deploy にアプリコードに対応した .env が設定されている必要があります"
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
    echo "エラー: アプリコード '$BASENAME' が不正です"
    exit 1
fi
if ! [[ "$DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
    echo "エラー: ドメイン '$DOMAIN' が不正です"
    exit 1
fi

DIR=$BASEDIR/$BASENAME
VHOST_LIVE=$HTTPD_CONF_DIR/vhost-$BASENAME-live.conf
VHOST_TEST=$HTTPD_CONF_DIR/vhost-$BASENAME-test.conf
SUPERVISOR_CONF=$SUPERVISOR_CONF_DIR/$BASENAME.conf
UNIT=mir-$BASENAME
SERVICE_FILE=$SYSTEMD_DIR/$UNIT.service
TIMER_FILE=$SYSTEMD_DIR/$UNIT.timer

# 既存のプロジェクトを上書きしないよう、作る予定のファイルが1つでもあれば中止する
for f in $DIR $VHOST_LIVE $VHOST_TEST $SUPERVISOR_CONF $SERVICE_FILE $TIMER_FILE; do
    if [ -e "$f" ]; then
        echo "エラー: すでに $f が存在しています"
        exit 1
    fi
done

if [ ! -x $SETUP_ENV ]; then
    echo "エラー: $SETUP_ENV がないため、deploy から .env を取得できません"
    exit 1
fi

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

# storage / bootstrap/cache を apache と ec2-user の両方で読み書きできるようにする
set_laravel_perms() {
    if [ -x $PERMS_SCRIPT ]; then
        $PERMS_SCRIPT "$1" || abort "$PERMS_SCRIPT に失敗しました ($1)"
    else
        echo "警告: $PERMS_SCRIPT がないため、storage のパーミッションを設定していません ($1)"
    fi
}

# .env の値を取り出す（例: env_value DB_HOST）
env_value() {
    grep "^$1=" "$DIR/live/.env" | head -1 | cut -d = -f 2-
}

echo "GITコード        : $GITNAME"
echo "gitリポジトリ    : $GIT_SSH"
echo "アプリコード: $BASENAME"
echo "本番URL          : $DOMAIN / test-$DOMAIN"
echo "設置場所         : $DIR/sky (live), $DIR/fish (test)"
echo ".env             : deploy から取得"
echo "で作成します。中止する場合は 5 秒以内に Ctrl-C を押してください。"
echo

sleep 5

# 1. 雛形を先にすべて取得する（途中で失敗して中途半端に設置されないように）
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

for t in etc_httpd_confd_vhost_conf_live etc_httpd_confd_vhost_conf_test etc_supervisord_confd_conf \
         etc_sytemd_system_BASENAME_service etc_sytemd_system_BASENAME_timer; do
    if ! curl -fsS -o "$TMP/$t.txt" "$TEMPLATE_URL/$t.txt"; then
        echo "エラー: 雛形 $t.txt を取得できませんでした。中止します"
        exit 1
    fi
done

# 2. プロジェクトを sky (live) / fish (test) の2か所に設置する
$SUDO mkdir -p "$DIR" || abort "$DIR を作成できません"
$SUDO chown $EXEC_USER "$DIR" || abort "$DIR の所有者を変更できません"

for stage in sky fish; do
    echo
    echo "===== $stage ====="
    cd "$DIR" || abort "$DIR に移動できません"

    git clone "$GIT_SSH" $stage || abort "git clone に失敗しました（$stage）"
    cd $stage || abort "$DIR/$stage に移動できません"

    # .env の取得や composer install の前に、PHP のバージョンへの対応を確認する（同じリポジトリなので sky だけ）
    if [ $stage = sky ]; then
        check_php_compat . || abort "PHP のバージョンに対応していません"
    fi

    $SETUP_ENV "$BASENAME" || abort "deploy から .env を取得できませんでした（$stage）"
    composer install --no-dev --optimize-autoloader || abort "composer install に失敗しました（$stage）"
    set_laravel_perms "$DIR/$stage"
    git pull
done

cd "$DIR" || abort "$DIR に移動できません"
ln -s sky live
ln -s fish test

# 3. vhost / supervisor / systemd のファイルを設置する
cd "$TMP" || exit 1

for f in etc_httpd_confd_vhost_conf_live.txt etc_httpd_confd_vhost_conf_test.txt; do
    $SED -i -e "s/DOMAIN/$DOMAIN/g" -e "s/BASENAME/$BASENAME/g" $f
done
for f in etc_supervisord_confd_conf.txt etc_sytemd_system_BASENAME_service.txt etc_sytemd_system_BASENAME_timer.txt; do
    $SED -i -e "s/BASENAME/$BASENAME/g" $f
done

$SUDO install -m 0644 etc_httpd_confd_vhost_conf_live.txt "$VHOST_LIVE"
$SUDO install -m 0644 etc_httpd_confd_vhost_conf_test.txt "$VHOST_TEST"
$SUDO install -m 0644 etc_supervisord_confd_conf.txt "$SUPERVISOR_CONF"
$SUDO install -m 0644 etc_sytemd_system_BASENAME_service.txt "$SERVICE_FILE"
$SUDO install -m 0644 etc_sytemd_system_BASENAME_timer.txt "$TIMER_FILE"

# 4. timer を有効にする（live で artisan schedule:run を毎分実行）
echo
echo "===== timer ====="
$SUDO systemd-analyze verify "$SERVICE_FILE" "$TIMER_FILE" 2>/dev/null
$SUDO $SYSTEMCTL daemon-reload
$SUDO $SYSTEMCTL enable "$UNIT.timer"
$SUDO $SYSTEMCTL restart "$UNIT.timer"
$SYSTEMCTL list-timers "$UNIT.timer" --no-pager

# 5. 念のため最新にして、パーミッションを設定し直す
for stage in live test; do
    (cd "$DIR/$stage" && git pull)
    set_laravel_perms "$DIR/$stage"
done

echo
echo "設置しました:"
echo "  $DIR/sky  (live → $DOMAIN)"
echo "  $DIR/fish (test → test-$DOMAIN)"
echo "  $VHOST_LIVE"
echo "  $VHOST_TEST"
echo "  $SUPERVISOR_CONF"
echo "  $SERVICE_FILE（有効にしました）"
echo "  $TIMER_FILE（有効にしました）"

# 6. 残りの作業（コマンドの表示だけで、実行はしない）
cat <<EOF

========================================================
以下は手で実行してください
========================================================

[1. mysql（deploy から取得した .env の値）]
DB_HOST     : $(env_value DB_HOST)
DB_DATABASE : $(env_value DB_DATABASE)
DB_USERNAME : $(env_value DB_USERNAME)
DB_PASSWORD : $(env_value DB_PASSWORD)

[2. mysql]
# RDS にマスターユーザーで接続する（ローカルの MariaDB なら sudo mysql）
mysql -u <RDSのマスターユーザー> -p -h <RDSのエンドポイント>
create database DATABASE_NAME default charset utf8mb4;
create user '${BASENAME}_prd_user'@'%' identified by '${BASENAME}_prd_pass_XXXX';
grant all on DATABASE_NAME.* to '${BASENAME}_prd_user'@'%';

[3. migration]
cd $DIR/live
php artisan migrate

[4. Route 53 / /etc/hosts]
$DOMAIN と test-$DOMAIN を、このサーバに向ける
sudo sh -c 'printf "127.0.0.1   loopback-$DOMAIN\n127.0.0.1   loopback-test-$DOMAIN\n" >> /etc/hosts'

[5. httpd]
cat $VHOST_LIVE
cat $VHOST_TEST
sudo apachectl configtest && sudo systemctl reload httpd

[6. supervisor / queue worker]
# 雛形はコメントアウトされているので、queue を使う場合は # を外す
sudo vi $SUPERVISOR_CONF
sudo /usr/local/bin/supervisorctl update
sudo /usr/local/bin/supervisorctl status

[7. timer の確認（有効化は済み）]
systemctl list-timers $UNIT.timer
journalctl -n 50 -u $UNIT.service

[Web]
http://$DOMAIN/
http://test-$DOMAIN/
EOF
