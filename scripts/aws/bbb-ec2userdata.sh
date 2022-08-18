#!/bin/bash

# cat /var/log/cloud-init-output.log
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -yq

echo "Autoremove and Autoclean System..."
apt autoremove -yq && apt autoclean -yq

# reboot now
# associate IP with bbb.adrianoruseler.com

sudo su 
wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -w -v xenial-22 -s bbb.adrianoruseler.com -e ruseler@utfpr.edu.br -g


# Create admin user
docker exec greenlight-v2 bundle exec rake user:create["ruseler","ruseler@utfpr.edu.br","7vN41oujwI","admin"]
docker exec greenlight-v2 bundle exec rake user:create["Prof. Adriano Ruseler","ruseler@professores.utfpr.edu.br","7vN41oujwI","admin"]



### NOT WORKING FOR IP CHANGE ###
# bbb-conf --secret
sudo bbb-conf --setip bbb.adrianoruseler.com

# Gets public hostname
# PUBHOST=$(ec2metadata --public-hostname | cut -d : -f 2 | tr -d " ")
# LOCHOST=$(ec2metadata --local-hostname | cut -d : -f 2 | tr -d " ")

PUBIP=$(ec2metadata --public-ipv4)
LOCIP=$(ec2metadata --local-ipv4)
sed -i 's/local_ip_v4=.*/local_ip_v4='"$LOCIP"'"\/>/' /opt/freeswitch/etc/freeswitch/vars.xml
sed -i 's/external_rtp_ip=.*/external_rtp_ip='"$PUBIP"'"\/>/' /opt/freeswitch/etc/freeswitch/vars.xml
sed -i 's/external_sip_ip=.*/external_sip_ip='"$PUBIP"'"\/>/' /opt/freeswitch/etc/freeswitch/vars.xml
sed -i 's/"wss-binding"  value=".*/"wss-binding"  value="'"$PUBIP"':7443"\/>/' /opt/freeswitch/etc/freeswitch/sip_profiles/external.xml
sed -i 's/proxy_pass https:\/\/.*/proxy_pass https:\/\/'"$PUBIP"':7443;/' /etc/bigbluebutton/nginx/sip.nginx
sed -i 's/- ip: .*/- ip: '"$PUBIP"'/' /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml
sed -i 's/localIpAddress: .*/localIpAddress: '"$LOCIP"'/' /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml
sed -i 's/sip_ip: .*/sip_ip: '"$LOCIP"'/' /usr/local/bigbluebutton/bbb-webrtc-sfu/config/default.yml



# Edit framerate
sudo nano /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml


# sed -i 's/webmaster@localhost/admin@fake.mail/' /etc/apache2/sites-available/moodle-ssl.conf

sudo bbb-conf --restart

bbb-conf --check

# Updating BBB and Greenlight 
sudo su
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -yq

echo "Autoremove and Autoclean System..."
apt autoremove -yq && apt autoclean -yq
cd ~/greenlight
docker pull bigbluebutton/greenlight:v2
docker-compose down
docker-compose up -d

bbb-conf --restart

# erro 1002
sudo bbb-conf --setip bbb.adrianoruseler.com

