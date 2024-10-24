#!/bin/bash

# Load .env
ENVFILE='.env'
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
fi

HOMEDIR=$(pwd)
#sudo hostnamectl set-hostname server.local

datastr=$(date) # Generates datastr
echo "" >>$ENVFILE
echo "# ----- $datastr -----" >>$ENVFILE
echo "HOMEDIR=\"$HOMEDIR\"" >>$ENVFILE

echo "Update and Upgrade System..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Add locales pt_BR, en_US, en_AU..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_AU.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "Set timezone and locale..."
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot

echo "Install apache2..."
sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt-get update
sudo apt-get install -y apache2
sudo a2enmod ssl rewrite headers deflate

echo "Redirect http to https..."
sed -i '/combined/a \\n\tRewriteEngine On \n\tRewriteCond %{HTTPS} off \n\tRewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}' /etc/apache2/sites-available/000-default.conf

echo "Create selfsigned certificate..."
LOCALSITEURL=$(hostname)
echo "LOCALSITEURL=\"$LOCALSITEURL\"" >>$ENVFILE

openssl req -x509 -out /etc/ssl/certs/${LOCALSITEURL}-selfsigned.crt -keyout /etc/ssl/private/${LOCALSITEURL}-selfsigned.key \
	-newkey rsa:2048 -nodes -sha256 \
	-subj '/CN='${LOCALSITEURL}$'' -extensions EXT -config <(
		printf "[dn]\nCN='${LOCALSITEURL}$'\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:'${LOCALSITEURL}$'\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth"
	)

echo "Change default site certificate..."
sed -i 's/ssl-cert-snakeoil.pem/'${LOCALSITEURL}$'-selfsigned.crt/' /etc/apache2/sites-available/default-ssl.conf
sed -i 's/ssl-cert-snakeoil.key/'${LOCALSITEURL}$'-selfsigned.key/' /etc/apache2/sites-available/default-ssl.conf

echo "Enable site certificate..."
sudo a2ensite default-ssl.conf
sudo systemctl reload apache2

echo "Install some sys utils..."
sudo apt-get install -y git p7zip-full

echo "Install python..."
sudo apt-get install -y python3

# Select php version
# sudo update-alternatives --config php

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "Install pdftoppm poppler-utils - Poppler is a PDF rendering library based on the xpdf-3.0 code base."
sudo apt-get install -y poppler-utils

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-en aspell-pt-br aspell-doc spellutils

echo "Add the following PHP PPA repository"
sudo add-apt-repository ppa:ondrej/php -y && sudo apt-get update

echo "Install php7.8 for apache..."
sudo apt-get install -y php8.0 libapache2-mod-php8.0 php-common php8.0-cli php8.0-common php8.0-opcache php8.0-readline php8.0-fpm

echo "Install php7.8 extensions..."
sudo apt-get install -y php8.0-curl php8.0-zip php8.0-intl php8.0-xmlrpc php8.0-soap php8.0-xml php8.0-gd php8.0-ldap php8.0-mbstring php8.0-mysql php8.0-imagick php8.0-tidy

# Cache related
sudo apt-get install -y php8.0-redis php8.0-memcached php8.0-apcu php8.0-mongodb

echo "Restart apache server..."
sudo service apache2 restart

# Set PHP ini
sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/8.0/apache2/php.ini
sed -i 's/post_max_size =.*/post_max_size = 256M/' /etc/php/8.0/apache2/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/8.0/apache2/php.ini
sed -i 's/;max_input_vars =.*/max_input_vars = 6000/' /etc/php/8.0/apache2/php.ini

# Set PHP CLI ini
sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/8.0/cli/php.ini
sed -i 's/post_max_size =.*/post_max_size = 256M/' /etc/php/8.0/cli/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/8.0/cli/php.ini
sed -i 's/;max_input_vars =.*/max_input_vars = 6000/' /etc/php/8.0/cli/php.ini

systemctl reload apache2

# populate site folder with index.php and phpinfo
touch /var/www/html/index.php
echo '<?php  phpinfo(); ?>' >>/var/www/html/index.php

systemctl reload apache2
cd /var/www/html
ls -l
sudo mv index.html index.html.bkp
cd $HOMEDIR

echo "Install pwgen..."
# https://www.2daygeek.com/5-ways-to-generate-a-random-strong-password-in-linux-terminal/
sudo apt-get install -y pwgen # Install pwgen

echo "Install MariaDB..."
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash
sudo apt-get install mariadb-server mariadb-client mariadb-backup

DBROOTPASS=$(pwgen -s 16 1) # Generates ramdon password for db root user
DBADMPASS=$DBROOTPASS       # Generates ramdon password for db admin
echo "DBROOTPASS=\"$DBROOTPASS\"" >>$ENVFILE
echo "DBADMPASS=\"$DBADMPASS\"" >>$ENVFILE

echo "mysql root pass is: "$DBROOTPASS
echo "dbadmin pass is: "$DBROOTPASS
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('"$DBROOTPASS"') WHERE User = 'root'"
mysql -e "CREATE USER 'dbadmin'@'localhost' IDENTIFIED BY '"$DBADMPASS"';"
mysql -e "GRANT ALL PRIVILEGES ON * . * TO 'dbadmin'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES"

sudo echo "\
[client]
default-character-set = utf8mb4

[mysqld]
innodb_file_format = Barracuda
innodb_file_per_table = 1
innodb_large_prefix

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake
innodb_read_only_compressed=OFF

[mysql]
default-character-set = utf8mb4" >>/etc/mysql/my.cnf

sudo echo "[client]" >>/root/.my.cnf
sudo echo 'user="dbadmin"' >>/root/.my.cnf
sudo echo 'password="'$DBADMPASS'"' >>/root/.my.cnf
cat /root/.my.cnf

sudo systemctl restart mariadb.service

#echo "Install TeX..."
#sudo apt-get install -y texlive imagemagick

#echo "Install Universal Office Converter..."
#sudo apt-get install -y unoconv
#sudo chown www-data /var/www

# echo "Install maxima, gcc and gnuplot (Stack question type for Moodle) ..."
# sudo apt-get install -y maxima gcc gnuplot

#sudo apt install memcached libmemcached-tools

# https://redis.io/download
# sudo apt-get install redis-server
# sudo systemctl enable redis-server.service
# sudo nano /etc/redis/redis.conf
# sudo systemctl restart redis-server.service

# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
#wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
#echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
#sudo apt-get update
#sudo apt-get install -y mongodb-org
#sudo systemctl enable mongod
#sudo systemctl start mongod

# TODO
DEBIAN_FRONTEND=noninteractive apt-get install -qq slapd ldap-utils ldapscripts
LDAPROOTPASS=$(pwgen -s 16 1) # Generates ramdon password for db root user
echo "LDAP root pass is: "$LDAPROOTPASS
slappasswd -s $LDAPROOTPASS
echo "LDAPROOTPASS=\"$LDAPROOTPASS\"" >>$ENVFILE

echo "Install Doker and compose..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker run hello-world

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Install nodejs..."
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Update and Upgrade System..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

cd $HOMEDIR
mkdir scripts
cd scripts
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/UpdateScripts.sh -O UpdateScripts.sh
chmod a+x UpdateScripts.sh
./UpdateScripts.sh

cd $HOMEDIR
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
echo ""
