amazon-linux-extras list | grep php
sudo amazon-linux-extras disable php8.0
amazon-linux-extras list | grep php
sudo amazon-linux-extras enable php8.2
amazon-linux-extras list | grep php
sudo yum remove 'php*'

sudo yum install -y php php-bcmath php-gd php-mbstring php-opcache php-xml php-pdo php-fpm php-mysqlnd
#sudo yum install -y php-pecl-imagick
#sudo yum install php-cli php-json

sudo yum install -y gcc
sudo yum install -y php-devel
sudo yum install -y php-pear
sudo yum install -y php-intl
sudo pecl install igbinary
echo "extension=igbinary.so" | sudo tee /etc/php.d/50-igbinary.ini

sudo pecl install redis
---- igbinaryはnoにする
echo "extension=redis.so" | sudo tee /etc/php.d/50-redis.ini

# imagick
sudo yum install -y ImageMagick ImageMagick-devel
sudo pecl install imagick
echo "extension=imagick.so" | sudo tee /etc/php.d/50-imagick.ini

sudo cp /etc/php.ini /etc/php.ini.default
sudo sed -i "s/expose_php = On/expose_php = Off/" /etc/php.ini
sudo sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
sudo sed -i "s/post_max_size = 8M/post_max_size = 16M/" /etc/php.ini
sudo sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 16M/" /etc/php.ini
sudo sed -i "s/; max_input_vars = 1000/max_input_vars = 5000/" /etc/php.ini
sudo sed -i "s/;date.timezone =/date.timezone = Asia\\/Tokyo/" /etc/php.ini
diff /etc/php.ini.default /etc/php.ini

php -v

sudo systemctl restart httpd

sudo service httpd graceful




/etc/php.ini.rpmsave

=====================================================================
#削除中:
# php                                               x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  9.9 M
# php-bcmath                                        x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                   72 k
# php-cli                                           x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                   18 M
# php-common                                        x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                   15 M
# php-devel                                         x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                   11 M
# php-fpm                                           x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  6.1 M
# php-gd                                            x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  749 k
# php-intl                                          x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  865 k
# php-mbstring                                      x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  2.0 M
# php-mysqlnd                                       x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  829 k
# php-opcache                                       x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  2.5 M
# php-pdo                                           x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  398 k
# php-pear                                          noarch                                  1:1.10.12-9.amzn2                                  @amzn2-core                                         2.1 M
# php-pecl-imagick                                  x86_64                                  3.5.1-1.amzn2.0.1                                  @amzn2extra-php8.0                                  504 k
# php-process                                       x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  203 k
# php-xml                                           x86_64                                  8.0.30-1.amzn2                                     @amzn2extra-php8.0                                  724 k
#