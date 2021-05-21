#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

koecyumon-1a
koecyumon-2a
koecyumon-batch-a

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

sudo su --login ec2-user

# Show HOSTNAME to PROMPT
echo 'シェルプロンプトにホスト名を表示...'
sudo vi /etc/profile.d/prompt.sh
export NICKNAME=prd1-pubsec
sudo sed -i "s/\\\u@\\\h /\\\u@\$NICKNAME /" /etc/bashrc

cd ~
mkdir -p bin
cd bin

curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/amazon_linux2_init.sh
chmod a+x amazon_linux2_init.sh
./amazon_linux2_init.sh




#######################################################
# 以下手動
echo '================================================='
echo '以下手動'

#echo 'my-userにsudo権限を付与'
#echo '$ sudo visudo'
#echo '追加> #my-user ALL=(ALL) NOPASSWD: ALL'
#echo

echo 'git用のsshの登録'
ssh-keygen -t rsa
----------- 続けないこと
cat ~ec2-user/.ssh/id_rsa.pub

git config --global user.name prd2-miraie-1d
git config --global user.email ss@mir-ai.co.jp


# github.com にSSHKEYを追加
# https://github.com/settings/ssh/new
# git用の.ssh/configを作成
ssh -T git@github.com

## Add crontab
* * * * * cd /var/www/production/ && /home/ec2-user/bin/skyfish_remote_update.py >> /dev/null 2>&1

echo 'セキュリティパッチを自動適用...'
sudo yum install yum-cron -y
sudo cp /etc/yum/yum-cron.conf /etc/yum/yum-cron.conf.backup
sudo sed -i "s/^update_cmd.*$/update_cmd = security/g" /etc/yum/yum-cron.conf
sudo sed -i "s/^apply_updates.*$/apply_updates = yes/g" /etc/yum/yum-cron.conf
diff /etc/yum/yum-cron.conf.backup /etc/yum/yum-cron.conf
sudo systemctl start yum-cron
sudo systemctl enable yum-cron
sudo systemctl status yum-cron



echo 'mariadbをインストール...'
sudo amazon-linux-extras disable php7.4
sudo amazon-linux-extras enable lamp-mariadb10.2-php7.2=stable
sudo yum install -y mariadb-server
sudo amazon-linux-extras disable lamp-mariadb10.2-php7.2

echo 'mariadbの起動設定'
sudo systemctl start mariadb
sudo systemctl status mariadb
sudo systemctl enable mariadb
sudo systemctl is-enabled mariadb

echo 'mariadbのセキュリティ設定'
sudo mysql_secure_installation

echo 'redisをインストール...'
sudo amazon-linux-extras install -y redis4.0=stable
sudo systemctl start redis.service
sudo systemctl enable redis.service
sudo systemctl is-enabled redis.service
sudo systemctl status redis.service

echo 'python3.8をインストール...'
sudo amazon-linux-extras install -y python3.8=stable

echo 'cloudwatch カスタムメトリクス送信設定...'
sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm CloudWatchMonitoringScripts-1.2.2.zip
sudo mv aws-scripts-mon /root



echo '以下のポリシーを持つRoleを作成して、EC2に割当(SSM, Cloudwatch)'
echo "AmazonEC2RoleforSSM"
echo "CloudWatchAgentServerPolicy"
echo "AmazonSSMManagedInstanceCore"


echo 'CloudWatchカスタムメトリクスをcrontabに追加'
sudo vi /etc/crontab
# */5 * * * * root /root/aws-scripts-mon/mon-put-instance-data.pl --mem-util --mem-used --mem-avail --disk-path=/ --disk-space-util --disk-space-used --disk-space-avail --from-cron > /dev/null 2>&1

echo 'Google Vision API用設定情報CONFIGファイルを各サーバのローカルにコピー'
#cp ODPF-hamamatsu-e3ef389d60ae.json $HOME/.config/gcloud/application_default_credentials.json

#crontab -e
#*/10 * * * * /home/ec2-user/bin/skyfish_host_status.py >> /dev/null 2>&1


echo 'Reboot'
sudo reboot -n


cd bin
./skyfish_setup.sh


161L-mir-admin-v1
admin.hamamatsu.odpf.net
git@github.com:mir-aie/161L-mir-admin-v1.git

#/etc/supervisord/conf.d/001L-salvatore-laravel.conf
#[program:001L-salvatore-laravel-queue]
#process_name=%(program_name)s_%(process_num)02d
#directory=/var/www/production/001L-salvatore-laravel/live/
#command=/usr/bin/php artisan queue:work --queue=orders_prod,slack --sleep=5
#autostart=true
#autorestart=true
#user=ec2-user
#numprocs=4
#redirect_stderr=true
#stdout_logfile=/var/www/001L-salvatore-laravel/live/storage/logs/queue-worker.log
#supervisorctl reload


#echo 'my-userに.sshを付与'
#echo 'sudo rsync -a ~ec2-user/.ssh/authorized_keys ~my-user/.ssh/'
#echo 'sudo chown -R my-user:my-user ~my-user/.ssh'
#echo 'sudo chmod 700 ~my-user/.ssh/'
#echo 'sudo chmod 600 ~my-user/.ssh/**'
#echo 'curl -o config https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/home_my_user_ssh_config.txt'
#echo 'mv config ~my-user/.ssh/'
#echo 'chmod 600 ~my-user/.ssh/config'
#echo 'chmod 600 ~ec2-user/.ssh/config'

# ffmpeg
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/bin/ffmpeg
chmod a+x ffmpeg

hamamatsu.odpf.net
NS
ns-1324.awsdns-37.org.
ns-1949.awsdns-51.co.uk.
ns-918.awsdns-50.net.
ns-260.awsdns-32.com.


SWAP
sudo dd if=/dev/zero of=/swapfile bs=128M count=32
sudo chmod 600 /swapfile 
sudo mkswap /swapfile 
sudo swapon /swapfile 
sudo swapon -s 
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# mecab
https://zenn.dev/yukiko_bass/scraps/0f91d67da6d444

sudo yum update -y
sudo yum groupinstall -y "Development Tools"

wget 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7cENtOXlicTFaRUE' -O mecab-0.996.tar.gz
tar xzf mecab-0.996.tar.gz
cd mecab-0.996
./configure
make
make check
sudo make install
cd -
rm -rf mecab-0.996*

git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git
./mecab-ipadic-neologd/bin/install-mecab-ipadic-neologd -n -y

sudo sed -i -e "s|^dicdir.*$|dicdir = /usr/local/lib/mecab/dic/mecab-ipadic-neologd|" $(mecab-config --sysconfdir)/mecabrc

cd ~/bin
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/mecab_update_dict_neologd.sh
chmod a+x mecab_update_dict_neologd.sh

crontab
# 毎週火曜日と金曜日にmecabの辞書を更新
# https://github.com/neologd/mecab-ipadic-neologd/blob/master/README.ja.md
00 03 * * 2,5 /home/ec2-user/bin/mecab_update_dict_neologd.sh > /dev/null 2>&1


# Polly server daemonize
sudo vi /etc/supervisord/conf.d/196L-polly-speech-v2.conf
[program:196L-polly-speech-v2]
process_name=%(program_name)s_%(process_num)02d
directory=/var/www/production/196L-polly-speech-v2
command=/var/www/production/196L-polly-speech-v2/polly-speech-server.py
autostart=true
autorestart=true
user=ec2-user
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/production/196L-polly-speech-v2/log/196L-polly-speech-v2.log



/home/ec2-user/mecab-ipadic-neologd/cron-update.log