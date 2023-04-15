#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/10/17
# Target    Amazon Linux 2

sudo systemctl stop httpd

sudo amazon-linux-extras disable php8.0

sudo yum remove -y 'php*'
sudo rm /etc/php.d/50-igbinary.ini
sudo rm /etc/php.d/50-redis.ini

echo 'phpをインストール...'
sudo amazon-linux-extras enable php8.1=stable
sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache pphp-xml php-pdo php-fpm php-mysqlnd
sudo cp /etc/php.ini /etc/php.ini.default
sudo sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sudo sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

# igbinary, phpredis 
sudo yum install -y gcc
sudo yum install -y php-devel
sudo yum install -y php-pear
sudo yum install -y php-intl
sudo pecl install igbinary
echo "extension=igbinary.so" | sudo tee /etc/php.d/50-igbinary.ini

# phpredis 
sudo pecl install redis
---- igbinaryはnoにする
echo "extension=redis.so" | sudo tee /etc/php.d/50-redis.ini

# imagick
yum install ImageMagick ImageMagick-devel
sudo pecl install imagick
echo "extension=imagick.so" | sudo tee /etc/php.d/50-imagick.ini

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
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_setup_stage.py

chmod +x *.sh
chmod +x *.py

sudo reboot now

