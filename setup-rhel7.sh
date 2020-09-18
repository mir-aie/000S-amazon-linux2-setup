#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

prd-hmpf-ec2-cms-01
prd-hmpf-ec2-cms-02
prd-hmpf-ec2-web-01
prd-hmpf-ec2-web-02
prd-hmpf-ec2-web-03
prd-hmpf-ec2-web-04
stg-hmpf-ec2-cms-01
stg-hmpf-ec2-web-01




hmpf-cms-stg
prd-hmpf-cms-01

sudo su --login ec2-user

sudo hostname stg-hmpf-web-01

sudo vi /etc/sysconfig/network
HOSTNAME=stg-hmpf-web-01


sudo yum install -y httpd

sudo systemctl start httpd.service
sudo systemctl enable httpd.service
sudo systemctl status httpd.service


#===============================================




# (必須)
# ホスト名を個々に設定する

SERVER_NAME=dev2.mi-sp.net
GIT_USERNAME=miraie
GIT_EMAIL=email@miraie.com

INSTANCE_ID=`curl 169.254.169.254/latest/meta-data/instance-id/`
PUBLIC_IPV4=`curl 169.254.169.254/latest/meta-data/public-ipv4/`

echo "SERVER_NAME=$SERVER_NAME"
echo "INSTANCE_ID=$INSTANCE_ID"
echo "PUBLIC_IPV4=$PUBLIC_IPV4"

# Show HOSTNAME to PROMPT
echo 'シェルプロンプトにホスト名を表示...'
sudo sh -c 'echo "export NICKNAME=${SERVER_NAME}" > /etc/profile.d/prompt.sh'
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
sudo systemctl is-enabled httpd
curl -o index.html https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/var_www_html_index.html
sudo mv index.html /var/www/html/
curl -o security.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_security_conf.txt
sudo mv security.conf /etc/httpd/conf.d/
# Safariのhttp2エラーを回避
sudo sed -i -e "s/^LoadModule/#LoadModule/g" /etc/httpd/conf.modules.d/10-h2.conf
# KeepAlive On
sudo sh -c 'echo "KeepAlive On" > /etc/httpd/conf.d/keepalive.conf'

# KeepAliveTimeout
sudo sh -c 'echo "KeepAliveTimeout 120" >> /etc/httpd/conf.d/keepalive.conf'
sudo systemctl start httpd
sudo systemctl status httpd
sudo systemctl enable httpd

echo 'mariadbをインストール...'
sudo amazon-linux-extras enable lamp-mariadb10.2-php7.2=stable
sudo yum install -y mariadb-server
sudo sudo amazon-linux-extras disable lamp-mariadb10.2-php7.2

echo 'phpをインストール...'
sudo amazon-linux-extras enable php7.4=stable
sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache php-pecl-igbinary php-pecl-redis php-xml php-pdo php-fpm php-mysqlnd
sudo cp /etc/php.ini /etc/php.ini.default
sudo sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sudo sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

echo 'redisをインストール...'
sudo amazon-linux-extras install -y redis4.0=stable
sudo systemctl status redis.service
sudo systemctl start redis.service
sudo systemctl enable redis.service
sudo systemctl is-enabled redis.service

echo 'python3.8をインストール...'
sudo amazon-linux-extras install -y python3.8=stable

echo 'gitをインストール...'
sudo yum install -y git
git config --global user.name miraie-hmpf-stg-01
git config --global user.email ss@mir-ai.co.jp

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

#echo 'my-userを作成...'
#sudo adduser my-user
#sudo usermod -G wheel my-user

echo 'remote用環境作成...'
sudo mkdir ~ec2-user/remote
sudo chown ec2-user ~ec2-user/remote
#sudo mkdir ~my-user/remote
#sudo chown my-user ~my-user/remote

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

#https://chariosan.com/2019/11/10/supervisor4_al2/
echo 'install supervisord'
sudo yum install -y python3
sudo pip3 install supervisor
echo_supervisord_conf > ~/supervisord.conf
sudo mkdir /etc/supervisord
sudo mv ~/supervisord.conf /etc/supervisord/supervisord.conf
sudo mkdir /etc/supervisord/conf.d
sudo cp /etc/supervisord/supervisord.conf /etc/supervisord/supervisord.conf.original
sudo sed -i "s/;\[inet_http_server\]/\[inet_http_server\]/" /etc/supervisord/supervisord.conf
sudo sed -i "s/;port=127.0.0.1:9001/port=127.0.0.1:9001/" /etc/supervisord/supervisord.conf
sudo sed -i "s/logfile=\/tmp\/supervisord.log/logfile=\/var\/log\/supervisord.log/" /etc/supervisord/supervisord.conf
sudo sed -i "s/\/tmp\/supervisord.pid/\/var\/run\/supervisord.pid/" /etc/supervisord/supervisord.conf
sudo sed -i "s/serverurl=unix:\/\/\/tmp\/supervisor.sock/; serverurl=unix:\/\/\/tmp\/supervisor.sock/" /etc/supervisord/supervisord.conf
sudo sed -i "s/;serverurl=http:\/\/127.0.0.1:9001/serverurl=http:\/\/127.0.0.1:9001/" /etc/supervisord/supervisord.conf
sudo sed -i "s/;\[include\]/\[include\]/" /etc/supervisord/supervisord.conf
sudo sed -i "s/;files = relative\/directory\/\*.ini/files = \/etc\/supervisord\/conf.d\/\*.conf/" /etc/supervisord/supervisord.conf
diff /etc/supervisord/supervisord.conf.original /etc/supervisord/supervisord.conf
curl -o supervisord.service https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_systemd_system_supervisord_service.txt 
sudo mv supervisord.service /etc/systemd/system/
sudo systemctl start supervisord
sudo systemctl status supervisord
sudo systemctl enable supervisord

#/etc/supervisord/conf.d/141L-call-v3.conf
#[program:141L-call-v3-queue]
#process_name=%(program_name)s_%(process_num)02d
#directory=/var/www/dev/141L-call-v3
#command=/usr/bin/php artisan queue:work
#autostart=true
#autorestart=true
#user=ec2-user
#numprocs=4
#redirect_stderr=true
#stdout_logfile=/var/www/dev/141L-call-v3/storage/logs/queue-worker.log



# 以下手動
echo '================================================='
echo '以下手動'

#echo 'my-userにsudo権限を付与'
#echo '$ sudo visudo'
#echo '追加> #my-user ALL=(ALL) NOPASSWD: ALL'
#echo

echo 'git用のsshの登録'
ssh-keygen -t rsa
cat ~ec2-user/.ssh/id_rsa.pub
# github.com にSSHKEYを追加
# https://github.com/settings/ssh/new
# git用の.ssh/configを作成
ssh -T git@github.com

#echo 'my-userに.sshを付与'
#echo 'sudo rsync -a ~ec2-user/.ssh/authorized_keys ~my-user/.ssh/'
#echo 'sudo chown -R my-user:my-user ~my-user/.ssh'
#echo 'sudo chmod 700 ~my-user/.ssh/'
#echo 'sudo chmod 600 ~my-user/.ssh/**'
#echo 'curl -o config https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/home_my_user_ssh_config.txt'
#echo 'mv config ~my-user/.ssh/'
#echo 'chmod 600 ~my-user/.ssh/config'
#echo 'chmod 600 ~ec2-user/.ssh/config'

echo 'CloudWatchカスタムメトリクスをcrontabに追加'
sudo vi /etc/crontab
# */5 * * * * root /root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --disk-path=/ --disk-space-util --disk-space-used --disk-space-avail --from-cron > /dev/null 2>&1

echo 'mariadbの起動設定'
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo systemctl is-enabled mariadb

echo 'mariadbのセキュリティ設定'
sudo mysql_secure_installation



echo '以下のポリシーを持つRoleを作成して、EC2に割当(SSM, Cloudwatch)'
echo "AmazonEC2RoleforSSM"
echo "CloudWatchAgentServerPolicy"
echo "AmazonSSMManagedInstanceCore"

# wkhtmltopdf
#https://wkhtmltopdf.org/downloads.html
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.amazonlinux2.x86_64.rpm
sudo yum install -y wkhtmltox-0.12.6-1.amazonlinux2.x86_64.rpm

cd /usr/share/fonts

# 日本語フォント
sudo wget https://ipafont.ipa.go.jp/IPAexfont/ipaexm00201.zip
sudo wget https://ipafont.ipa.go.jp/IPAexfont/ipaexg00201.zip
sudo unzip ipaexg00201.zip
sudo unzip ipaexm00201.zip
sudo rm  *.zip
fc-cache -fv
fc-list | grep -i ipa

echo 'Reboot'
sudo reboot -n

