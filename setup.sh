#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

# (必須)
# ホスト名を個々に設定する
HOSTNAME=mirai_dev_01
GIT_USERNAME=obata
GIT_EMAIL=obata@mir-ai.co.jp

echo "HOSTNAME=$HOSTNAME"

# Show HOSTNAME to PROMPT
echo 'シェルプロンプトにホスト名を表示'
sudo sh -c 'echo "export NICKNAME=${HOSTNAME}" > /etc/profile.d/prompt.sh'
sudo sed -i "s/\\\u@\\\h /\\\u@\$NICKNAME /" /etc/bashrc

echo 'システムファイル更新'
sudo yum update -y

echo 'タイムゾーン設定'
sudo timedatectl set-timezone Asia/Tokyo
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
sudo sed -i "s/\"UTC\"/\"Asia\\/Tokyo\"/" /etc/sysconfig/clock

echo '言語設定'
sudo localectl set-locale LANG=ja_JP.UTF-8
sudo localectl set-keymap jp106

echo 'SSHを高速化'
sudo sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config

echo 'httpdをインストール'
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl status httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd
sudo sh -c 'echo 'OK' > /var/www/html/index.html'

echo 'mariadbをインストール'
sudo amazon-linux-extras enable lamp-mariadb10.2-php7.2=stable
sudo yum install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl is-enabled mariadb
sudo sudo amazon-linux-extras disable lamp-mariadb10.2-php7.2

echo 'phpをインストール'
sudo amazon-linux-extras enable php7.4=stable
sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache php-pecl-igbinary php-pecl-redis php-xml
sudo cp /etc/php.ini /etc/php.ini.default
sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

echo 'redisをインストール'
sudo amazon-linux-extras install -y redis4.0=stable
sudo systemctl status redis.service
sudo systemctl start redis.service
sudo systemctl enable redis.service
sudo systemctl is-enabled redis.service

echo 'python3.8をインストール'
sudo amazon-linux-extras install -y python3.8=stable

echo 'gitをインストール'
sudo yum install -y git
git config --global user.name "$GIT_USERNAME"
git config --global user.email $GIT_EMAIL

echo 'composerをインストール'
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

echo 'nodeをインストール'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
node -v

echo '新規ユーザーを作成'
sudo adduser my-user
sudo usermod -G wheel my-user
sudo rsync -a ~/.ssh/authorized_keys ~my-user/.ssh/
sudo chown -R my-user:my-user ~my-user/.ssh
sudo chmod 700 ~my-user/.ssh/
sudo chmod 600 ~my-user/.ssh/**

echo 'remote用環境作成'
mkdir ~ec2-user/remote
mkdir ~my-user/remote

# 以下手動

echo 'my-userにsudo権限を付与'
echo '$ sudo visudo'
echo '追加> #my-user ALL=(ALL) NOPASSWD: ALL'
echo

echo 'mariadbのセキュリティ設定'
echo '$ sudo mysql_secure_installation'
echo

echo 'git用のsshの登録'
echo '$ ssh-keygen -t rsa'
echo '$ cat ~/.ssh/id_rsa.pub'
echo 'github にSSHKEYを追加'

