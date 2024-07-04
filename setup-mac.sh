direnv を使ったディレクトリごとのPHPバージョン設定
https://zenn.dev/ttskch/articles/e6f6b2af2972ab

brew install shivammathur/php/php@7.4
brew install shivammathur/php/php@8.0
brew install shivammathur/php/php@8.1
brew install shivammathur/php/php@8.2
brew install shivammathur/php/php@8.3
brew link --force --overwrite shivammathur/php/php@8.3

brew install shivammathur/extensions/igbinary@8.2
brew install shivammathur/extensions/imagick@8.2
brew install shivammathur/extensions/redis@8.2



node インストール
https://qiita.com/kyosuke5_20/items/c5f68fc9d89b84c0df09



brew install php@7.4
pecl install igbinary
pecl install redis


# Cleanup
brew list | grep php
brew uninstall php@7.x
rm -rf /usr/local/etc/php

brew install php@7.4

vi  /usr/local/Cellar/php@7.4/7.4.16//include/php/main/php_config.h

# /usr/local/Cellar/php@7.4/7.4.16//include/php/main/php_config.h 
#
# #define HAVE_ASM_GOTO 1
# をコメントアウトする
# (phpがコンパイルされたコンパイラと、macのコンパイラが違うため)

brew install igbinary


brew install redis

brew install mysql@5.7

== on migration ================================
% brew uninstall mysql
% brew uninstall --force mysql
% brew cleanup -s mysql
% brew prune

% rm -rf /usr/local/mysql
% rm -rf /Library/StartupItems/MYSQL
% rm -rf /Library/PreferencePanes/MySQL.prefPane
% rm -rf /Library/Receipts/mysql-.pkg
% rm -rf /usr/local/Cellar/mysql*
% rm -rf /usr/local/bin/mysql*
% rm -rf /usr/local/var/mysql*
% rm -rf /usr/local/etc/my.cnf
% rm -rf /usr/local/share/mysql*
% rm -rf /usr/local/opt/mysql

==============================

mysql_secure_installation
echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.zshrc

brew services start mysql@5.7

Or, if you don't want/need a background service you can just run:
  /usr/local/opt/mysql@5.7/bin/mysql.server start

==============================



sudo pecl config-set php_ini /usr/local/etc/php/8.1/php.ini
sudo pecl config-set php_bin /usr/local/opt/php@8.1/bin/php

pecl install redis


 brew install wkhtmltopdf


 # https://pauledenburg.com/setup-smtp-on-your-mac-and-send-mail-from-the-command-line/
# https://qiita.com/idani/items/77d1ed030a11a0ae5285
# brew install msmtp

# copy to ~/.msmtprc




  mysql
php 
  mpv
wkhtmltopdf
  iterm2
curl
ffmpeg
git
jq
node
php@8.2
python@3.9
wget






