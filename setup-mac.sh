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
