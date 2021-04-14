#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

apt-get upgrade
apt-get update
apt-get mpt123
apt install xfsprogs
mkdir /MIRAiE
mkdir /MIRAiE/ramdisk/
mkdir /MIRAiE/sd/

zramctl -f -s 200M
mkfs.xfs /dev/zram2
mount /dev/zram2 /MIRAiE/ramdisk

apt install supervisor



        ether 16:3a:5d:20:cb:e8  txqueuelen 1000  (Ethernet)
 sudo apt install lm-sensors

 armbianmonitor -r
 echo 'default-on' > nanopi\:green\:status/trigger
echo 'none' > nanopi\:green\:status/trigger
echo 'heartbeat' > nanopi\:green\:status/trigger
echo 'heartbeat' > /sys/class/leds/nanopi\:red\:pwr/trigger
echo 'heartbeat' > /sys/class/leds/nanopi\:green\:pwr/trigger
nanopi\:red\:status/trigger

