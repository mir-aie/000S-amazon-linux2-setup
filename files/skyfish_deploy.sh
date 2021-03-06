#!/bin/bash

# Susumu Obata
# 2020/9/18
#

echo "----------------------------"
echo "Skyfish Deploy"
echo "----------------------------"
echo

PWD=`pwd`
BASEDIR=/var/www/production
EXEC_USER=ec2-user
LSOPT=--full-time

if [ -d /Users/obatasusumu ]; then
    BASEDIR=/Users/obatasusumu/tmp/skyfish
    EXEC_USER=obatasusumu
    LSOPT=
fi

if [ ! `whoami` = $EXEC_USER ]; then
    echo "エラー: $EXEC_USER になって実行してください。例: sudo su --login $EXEC_USER"
    exit
fi

if [ ! `pwd | grep $BASEDIR` ]; then
        echo "エラー: $BASEDIR のプロジェクトディレクトリで実行してください(1)。"
        echo "例: cd $BASEDIR/012L-sky-fish"
        exit
fi

if [ ! -f test/composer.json ]; then
    echo "エラー: $BASEDIR のプロジェクトディレクトリで実行してください(2)。"
    echo "例: cd $BASEDIR/012L-sky-fish"
    exit
fi

if [ ! -f live/composer.json ]; then
    echo "エラー: $BASEDIR のプロジェクトディレクトリで実行してください(2)。"
    echo "例: cd $BASEDIR/012L-sky-fish"
    exit
fi

# 後にgit pullされたほう(.git/HEADのタイムスタンプが新しい方)を本番環境にする
if [ ! `ls -l $LSOPT */.git/FETCH_HEAD | grep -E 'sky|fish' | sort -r | head -1 | grep fish | wc -l` = 0 ]; then
    ln -nfs fish live
    ln -nfs sky test
    echo '「FISH。それは、さかな」 を本番環境として公開しました'
else
    ln -nfs sky live
    ln -nfs fish test
    echo '「SKY。それは、そら」 を本番環境として公開しました'
fi
