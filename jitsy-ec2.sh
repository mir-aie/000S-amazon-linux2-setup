https://jphblog.com/2020/04/jitsi-on-aws/

DOCKER_REV=1.26.2

sudo yum install docker git
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo curl -L https://github.com/docker/compose/releases/download/$DOCKER_REV/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
cd
git clone https://github.com/jitsi/docker-jitsi-meet
cd ~/docker-jitsi-meet
cp env.example .env
mkdir -p ~/.jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody,jicofo,jvb,jigasi,jibri}
./gen-passwords.sh
vi .env
docker-compose pull
sudo service docker start
cd ~/docker-jitsi-meet
docker-compose up -d
history
docker ps -a
docker-compose logs -f web


====
cd ~/docker-jitsi-meet
docker-compose down
sudo rm -rf ~/.jitsi-meet-cfg
docker-compose up -d
====

#
# Basic configuration options
#

# Directory where all configuration will be stored
CONFIG=~/.jitsi-meet-cfg        ← Let's Encrypt の証明書など、基本的な情報などが格納されるディレクトリ

# Exposed HTTP port
HTTP_PORT=80    ← 一般的な HTTP 用ポートにします

# Exposed HTTPS port
HTTPS_PORT=443  ← 一般的な HTTPS 用ポートにします

# System time zone
TZ=Asia/Tokyo   ← タイムゾーンを日本にします

# Public URL for the web service
PUBLIC_URL=https://meet.toaru.site  ←このホスト名は皆さんの環境にあわせ変更します。先頭の # を外すのを忘れずにします


#
# Let's Encrypt configuration
#

# Enable Let's Encrypt certificate generation
ENABLE_LETSENCRYPT=1        ←「1」が有効です。先頭の # を消します。

# Domain for which to generate the certificate
LETSENCRYPT_DOMAIN=meet.toaru.site  ←こちらは、環境にあわせて書き換えます

# E-Mail for receiving important account notifications (mandatory)
LETSENCRYPT_EMAIL=alice@example.jp  ← ここは、皆さんのメールアドレスを入力します（Let's Encrypt の有効期限通知が届きます）

jitsi.mi-sp.net 

Customize UI
https://technologyrss.com/how-to-customize-jitsi-meet-video-conference-server/


https://github.com/jitsi/docker-jitsi-meet/issues/551
