#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/10/17
# Target    Amazon Linux 2

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
curl -o index.html https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/var_www_html_index.html
sudo mv index.html /var/www/html/
curl -o security.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_security_conf.txt
sudo mv security.conf /etc/httpd/conf.d/
curl -o vhost-000.conf https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_httpd_confd_vhost_000.txt
sudo mv vhost-000.conf /etc/httpd/conf.d/


sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.org
sudo sed -i -e "s/{User-Agent}i\\\\\"\" combined$/{User-Agent}i\\\\\" %{X-Forwarded-For}i\" combined/" /etc/httpd/conf/httpd.conf
diff /etc/httpd/conf/httpd.conf.org  /etc/httpd/conf/httpd.conf

# Safariのhttp2エラーを回避
sudo sed -i -e "s/^LoadModule/#LoadModule/g" /etc/httpd/conf.modules.d/10-h2.conf
# KeepAlive On
sudo sh -c 'echo "KeepAlive On" > /etc/httpd/conf.d/keepalive.conf'

# KeepAliveTimeout
sudo sh -c 'echo "KeepAliveTimeout 120" >> /etc/httpd/conf.d/keepalive.conf'
sudo systemctl start httpd
sudo systemctl status httpd
sudo systemctl enable httpd

echo 'phpをインストール...'
sudo amazon-linux-extras enable php8.0=stable
sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache php-pecl-igbinary php-pecl-imagick php-pecl-redis php-xml php-pdo php-fpm php-mysqlnd
sudo cp /etc/php.ini /etc/php.ini.default
sudo sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sudo sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

echo 'gitをインストール...'
sudo yum install -y git

echo 'composerをインストール...'
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
composer --version

echo 'nodeをインストール...'
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
node -v


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
sudo mv laravel /etc/logrotate.d/laravel.conf
sudo chown root /etc/logrotate.d/laravel.conf
sudo chmod 0644 /etc/logrotate.d/laravel.conf

curl -o laravel_dev https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/etc_logrotated_laravel_dev.txt
sudo mv laravel_dev /etc/logrotate.d/laravel_dev.conf
sudo chown root /etc/logrotate.d/laravel_dev.conf
sudo chmod 0644 /etc/logrotate.d/laravel_dev.conf

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

echo 'install clamav'
sudo amazon-linux-extras install epel
sudo yum -y install clamav clamav-update clamd

cd ~
mkdir -p bin
cd bin
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_setup.sh
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_update_test.sh
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_deploy.sh
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_setup_env.py
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_setup_vhost.sh
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_remote_update.py
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_host_status.py
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_log_uploader.sh
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_host_status.py
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/clamscan.sh

chmod +x *.sh
chmod +x *.py
cd -

echo 'alias lg="tail -f storage/logs/laravel.log| grep -v -E '^#'"' >> ~/.bash_profile
echo 'alias lt="tail -1000 storage/logs/laravel.log| grep -v -E '^#'"' >> ~/.bash_profile

sudo yum -y install python-pip
sudo pip install boto

sudo pip3 install boto3


/home/ec2-user/bin/skyfish_host_status.py

