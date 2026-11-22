#!/bin/bash
# Laravel の storage / bootstrap/cache を apache と ec2-user の両方で読み書きできるようにする
#
# usage: laravel_shared_perms.sh [LARAVEL_ROOT]   (省略時はカレントディレクトリ)
#
# - 所有グループを apache に統一
# - ディレクトリに setgid を付け、新規ファイルが apache グループを継承するようにする
# - デフォルトACLで、どちらのユーザーが作ったファイルでも apache / ec2-user が rw できるようにする
#   (デフォルトACLがあるディレクトリ配下では umask の影響を受けない)
set -eu

DIR=${1:-.}
cd "$DIR"

if [ ! -f artisan ]; then
    echo "ERROR: $(pwd) は Laravel のルートではありません (artisan がない)"
    exit 1
fi

mkdir -p storage/logs storage/app/mir_tmp bootstrap/cache
touch storage/logs/laravel.log

for d in storage bootstrap/cache; do
    sudo chgrp -R apache "$d"
    sudo chmod -R u+rwX,g+rwX "$d"
    sudo find "$d" -type d -exec chmod g+s {} +
    # 既存ファイル用ACL
    sudo setfacl -R -m u:apache:rwX,u:ec2-user:rwX,g:apache:rwX,m:rwX "$d"
    # 新規作成ファイル用デフォルトACL (ディレクトリのみ)
    sudo find "$d" -type d -exec setfacl -d -m u::rwX,g::rwX,o::rX,u:apache:rwX,u:ec2-user:rwX,g:apache:rwX,m:rwX {} +
done

echo "OK: $(pwd)/storage, bootstrap/cache を apache / ec2-user 共有に設定しました"
getfacl -p storage/logs 2>/dev/null | sed -n '1,20p'
