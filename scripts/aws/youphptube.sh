#!/bin/bash

# cat /var/log/cloud-init-output.log
echo "#1 - Initial system setup"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -yq

echo "Autoremove and Autoclean System..."
apt autoremove -yq && apt autoclean -yq

# Set timezone and locale
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot


sudo apt-get install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-intl mysql-server mysql-client ffmpeg git libimage-exiftool-perl php-mbstring python
cd /var/www/html
sudo git clone https://github.com/WWBN/AVideo.git
sudo git clone https://github.com/WWBN/AVideo-Encoder.git # only for encoder
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl # only for encoder
sudo chmod a+rx /usr/local/bin/youtube-dl # only for encoder
sudo a2enmod rewrite
sudo phpenmod mbstring
sudo systemctl restart apache2

sudo apt-get install -y mysql-server mysql-client
sudo systemctl status mysql

echo "Install pwgen..."
# https://www.2daygeek.com/5-ways-to-generate-a-random-strong-password-in-linux-terminal/
apt install -y pwgen # Install pwgen

DBNAME=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon db name
DBUSER=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon user name
DBPASS=$(pwgen -s 14 1) # Generates ramdon password for db user
ROOTPASS=$(pwgen -s 16 1) # Generates ramdon password for db root
echo "DB Name: $DBNAME"
echo "DB User: $DBUSER"
echo "DB Pass: $DBPASS"
echo "ROOT Pass: $ROOTPASS"
echo ""

# https://stackoverflow.com/questions/49948350/phpmyadmin-on-mysql-8-0
# ALTER USER root@localhost IDENTIFIED WITH mysql_native_password BY 'PASSWORD';

#### https://stackoverflow.com/questions/24270733/automate-mysql-secure-installation-with-echo-command-via-a-shell-script

printf "y\n 0\n $ROOTPASS\n $ROOTPASS\n y\n y\n y\n y\n y\n" | sudo mysql_secure_installation # Testar isso, mais elegante!






 mysql_secure_installation <<EOF
y
0
$ROOTPASS
$ROOTPASS
y
y
y
y
y
EOF

## OK!!!!

# https://github.com/WWBN/AVideo/wiki/How-to-install-LAMP,-FFMPEG-and-Git-on-a-fresh-Ubuntu-18.x-for-AVideo-Platform-version-4.x-or-newer

PASSWDDB='F0yzMNExCQjpJQR3'

sudo mysql -e "use mysql; update user set authentication_string=PASSWORD("'$ROOTPASS'") where User='root'; flush privileges;"

#sudo mysqladmin -u root password $ROOTPASS
#sudo mysql -e "SET PASSWORD FOR root@localhost = PASSWORD('$ROOTPASS'); FLUSH PRIVILEGES;"
printf "y\n 0\n $ROOTPASS\n $ROOTPASS\n y\n y\n y\n y\n y\n" | sudo mysql_secure_installation

mysql -uroot -p${PASSWDDB} -e "CREATE DATABASE lsdb;"
mysql -uroot -p${PASSWDDB} -e "CREATE USER lsdb@localhost IDENTIFIED BY '$PASSWDDB';"
mysql -uroot -p${PASSWDDB} -e "GRANT ALL PRIVILEGES ON lsdb.* TO 'lsdb'@'localhost';"
mysql -uroot -p${PASSWDDB} -e "FLUSH PRIVILEGES;"
 
sudo systemctl restart mariadb



sudo mysql_secure_installation # set mysql-root-password




sudo apt-get install -y apache2 php libapache2-mod-php php-mysql php-curl php-gd php-intl php-mbstring mysql-server mysql-client ffmpeg git libimage-exiftool-perl python

sudo phpenmod mbstring
sudo a2enmod rewrite
sudo systemctl restart apache2


cd /var/www/html 

sudo git clone https://github.com/WWBN/AVideo.git 
sudo git clone https://github.com/WWBN/AVideo-Encoder.git 

sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl 
sudo chmod a+rx /usr/local/bin/youtube-dl 




