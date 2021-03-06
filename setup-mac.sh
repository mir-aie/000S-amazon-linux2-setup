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

