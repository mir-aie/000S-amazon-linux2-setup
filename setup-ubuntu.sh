#!/usr/bin/bash

# Author    obata@mir-ai.co.jp
# Created   2020/6/27
# Target    Amazon Linux 2

ssh-33-post-jitsy
ssh-34-vodeo-jitsy

# jitsi.mi-sp.net
sudo hostnamectl set-hostname video.mi-sp.net
sudo hostnamectl set-hostname vb1.mi-sp.net
sudo hostnamectl set-hostname vb2.mi-sp.net

sudo apt-get -y install nginx
sudo echo 'deb https://download.jitsi.org stable/' >> /tmp/jitsi-stable.list
sudo cp /tmp/jitsi-stable.list /etc/apt/sources.list.d/jitsi-stable.list
sudo wget -qO -  https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install jitsi-meet
    hostname: video.mi-sp.net

sudo apt update
sudo apt install -y apt-transport-https
sudo apt install -y nginx-full
sudo apt install -y gnupg2

sudo apt-get -y install openjdk-8-jre
sudo apt-get -y update && \
sudo apt-get -y install software-properties-common && \
sudo add-apt-repository -y ppa:certbot/certbot && \
sudo apt-get -y update && \
sudo apt-get -y install python-certbot-nginx && \
sudo apt install -y certbot

sudo vi /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh
sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh -m obata@mir-ai.co.jp
sudo certbot --nginx

sudo vi /etc/hosts
    52.199.197.78 jitsi.mi-sp.net

    curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg' 
    sudo echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
    sudo apt install jitsi-meet


# Your cert will expire on 2021-03-26. To obtain a new or tweaked

sudo ufw allow 80/tcp 
sudo ufw allow 443/tcp 
sudo ufw allow 4443/tcp 
sudo ufw allow 10000/udp 
sudo ufw enable
sudo ufw status
sudo ufw reload

How to Install Jitsi Meet (Meetrix.IO)
https://meetrix.io/blog/webrtc/jitsi/meet/installing.html







wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
./amazon-cloudwatch-agent.deb

--


sudo apt install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb


52.199.197.78

prosodyctl ySLuAlh1 jvb@auth.jitsi.mi-sp.net

echo deb http://packages.prosody.im/debian $(lsb_release -sc) main > /etc/apt/sources.list.d/prosody.list
wget https://prosody.im/files/prosody-debian-packages.key
apt-key add prosody-debian-packages.key
apt update


https://rohhie.net/show-the-status-of-jitsi-meet/
https://jochen.kirstaetter.name/authentication-jitsi-meet/

prosodyctl register miraie jitsi.mi-sp.net miraie


nano /etc/prosody/conf.d/$(hostname -f).cfg.lua


sudo service prosody restart
sudo service jicofo restart
sudo service jitsi-videobridge2 restart
sudo service nginx restart

sudo tail -f /var/log/prosody/prosody.log


jitsi.mi-sp.net

https://meetrix.io/blog/webrtc/jitsi/meet/installing.html
