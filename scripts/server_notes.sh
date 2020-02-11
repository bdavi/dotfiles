# Local SSH
# user and pass = brian
ssh -p 3022 brian@localhost

# Copy over SSH
# File
scp -P 3022 ./test.txt brian@localhost:~/test.txt

# Dir
scp -r -P 3022 ~/code/dotfiles brian@localhost:~/code/dotfiles

# Total disk usage
sudo du -sh /
# s=summary only
# h=human readable format

# Restart
sudo systemctl reboot

sudo apt install openssh-server

# Allow ssh and enable firewall
sudo ufw allow ssh
sudo ufw enable

# Install nginx
sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'

# systemctl status nginx
sudo apt-get install cockpit
sudo ufw allow 9090


# (Self Hosted) SSL CERT
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

sudo vim /etc/nginx/snippets/self-signed.conf

# Contents
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;

sudo vim /etc/nginx/snippets/ssl-params.conf






# nginx config
# location /dashboard {
#     proxy_pass  http://127.0.0.1:9090/;
# }
