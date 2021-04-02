cd ~/bin
curl -O https://raw.githubusercontent.com/mir-aie/000S-amazon-linux2-setup/master/files/skyfish_setup_vhost.sh
chmod +x *.sh

./skyfish_setup_vhost.sh 161L-mir-admin-v1 admin.hamamatsu.odpf.net

./skyfish_setup_vhost.sh 163L-mir-proc-v1 proc.hamamatsu.odpf.net

./skyfish_setup_vhost.sh 165L-mir-myna-v1 myna.hamamatsu.odpf.net

./skyfish_setup_vhost.sh 171L-mir-linebot-v1 linebot.hamamatsu.odpf.net

more /etc/httpd/conf.d/vhost-1*

sudo service httpd configtest

sudo service httpd restart

sudo ls -lrt /var/log/httpd/
