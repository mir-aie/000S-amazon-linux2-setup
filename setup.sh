#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

# (必須)
# ホスト名を個々に設定する
HOSTNAME=mirai_dev_01
GIT_USERNAME=obata
GIT_EMAIL=email

echo "HOSTNAME=$HOSTNAME"

# Show HOSTNAME to PROMPT
echo 'シェルプロンプトにホスト名を表示...'
sudo sh -c 'echo "export NICKNAME=${HOSTNAME}" > /etc/profile.d/prompt.sh'
sudo sed -i "s/\\\u@\\\h /\\\u@\$NICKNAME /" /etc/bashrc

echo 'システムファイル更新...'
sudo yum update -y

echo 'タイムゾーン設定...'
sudo timedatectl set-timezone Asia/Tokyo
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
sudo sed -i "s/\"UTC\"/\"Asia\\/Tokyo\"/" /etc/sysconfig/clock

echo '言語設定...'
sudo localectl set-locale LANG=ja_JP.UTF-8
sudo localectl set-keymap jp106

echo 'SSHを高速化...'
sudo sed -i "s/#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config

echo 'httpdをインストール...'
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl status httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd
curl -o index.html https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/var_www_html_index.html
sudo mv index.html /var/www/html/
curl -o security.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_security_conf.txt
sudo mv security.conf /etc/httpd/conf.d/

echo 'mariadbをインストール...'
sudo amazon-linux-extras enable lamp-mariadb10.2-php7.2=stable
sudo yum install -y mariadb-server
sudo sudo amazon-linux-extras disable lamp-mariadb10.2-php7.2

echo 'phpをインストール...'
sudo amazon-linux-extras enable php7.4=stable
sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache php-pecl-igbinary php-pecl-redis php-xml
sudo cp /etc/php.ini /etc/php.ini.default
sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

echo 'redisをインストール...'
sudo amazon-linux-extras install -y redis4.0=stable
sudo systemctl is-enabled redis.service

echo 'python3.8をインストール...'
sudo amazon-linux-extras install -y python3.8=stable

echo 'gitをインストール...'
sudo yum install -y git
git config --global user.name "$GIT_USERNAME"
git config --global user.email $GIT_EMAIL

echo 'composerをインストール...'
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

echo 'nodeをインストール...'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
node -v

echo 'セキュリティパッチを自動適用...'
sudo yum install yum-cron -y
sudo cp /etc/yum/yum-cron.conf /etc/yum/yum-cron.conf.backup
sudo sed -i "s/^update_cmd.*$/update_cmd = security/g" /etc/yum/yum-cron.conf
sudo sed -i "s/^apply_updates.*$/apply_updates = yes/g" /etc/yum/yum-cron.conf
diff /etc/yum/yum-cron.conf.backup /etc/yum/yum-cron.conf
sudo systemctl start yum-cron
sudo systemctl enable yum-cron
sudo systemctl status yum-cron

echo 'my-userを作成...'
sudo adduser my-user
sudo usermod -G wheel my-user

echo 'remote用環境作成...'
sudo mkdir ~ec2-user/remote
sudo chmod a+w ~ec2-user/remote
sudo mkdir ~my-user/remote
sudo chmod a+w ~my-user/remote

echo 'laravelコンテンツ用ディレクトリ作成...'
sudo mkdir /var/www/dev
sudo chmod a+w /var/www/dev
sudo mkdir /var/www/production
sudo chmod a+w /var/www/production

echo 'laravel logローテート設定...'
curl -o laravel https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_logrotated_laravel.txt
sudo mv laravel /etc/logrotate.d/laravel

echo 'cloudwatch カスタムメトリクス送信設定...'
sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm CloudWatchMonitoringScripts-1.2.2.zip
sudo mv aws-scripts-mon /root



# 以下手動
echo '================================================='
echo '以下手動'

echo 'my-userにsudo権限を付与'
echo '$ sudo visudo'
echo '追加> #my-user ALL=(ALL) NOPASSWD: ALL'
echo

echo 'my-userに.sshを付与'
echo 'sudo rsync -a ~/.ssh/authorized_keys ~my-user/.ssh/'
echo 'sudo chown -R my-user:my-user ~my-user/.ssh'
echo 'sudo chmod 700 ~my-user/.ssh/'
echo 'sudo chmod 600 ~my-user/.ssh/**'
echo 'curl -o config https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/home_my_user_ssh_config.txt'
echo 'mv config ~my-user/.ssh/'
echo 'chmod 600 ~my-user/.ssh/config'

echo 'mariadbのセキュリティ設定'
echo '$ sudo mysql_secure_installation'
echo

echo 'git用のsshの登録'
echo '$ ssh-keygen -t rsa'
echo '$ cat ~/.ssh/id_rsa.pub'
echo 'github.com にSSHKEYを追加'
echo 'https://github.com/settings/ssh/new'
echo 'git用の.ssh/configを作成'
echo '$ ssh -T git@github.com'
echo

echo '以下のポリシーを持つRoleを作成して、EC2に割当(SSM, Cloudwatch)'
echo "AmazonEC2RoleforSSM"
echo "CloudWatchAgentServerPolicy"
echo "AmazonSSMManagedInstanceCore"
echo

echo 'CloudWatchカスタムメトリクスをcrontabに追加'
echo 'sudo /etc/crontab'
echo '*/5 * * * * root /root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --disk-path=/ --disk-space-util --disk-space-used --disk-space-avail --from-cron > /dev/null 2>&1'
echo

echo 'mariadbの起動設定'
echo 'sudo systemctl start mariadb'
echo 'sudo systemctl enable mariadb'
echo 'sudo systemctl is-enabled mariadb'
echo

echo 'redisの起動設定'
echo 'sudo systemctl status redis.service'
echo 'sudo systemctl start redis.service'
echo 'sudo systemctl enable redis.service'
echo

