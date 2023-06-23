#!/bin/bash


echo "Add the following PHP PPA repository"
sudo add-apt-repository ppa:ondrej/php -y && sudo apt-get update

PHPVERS=('7.4' '8.0' '8.1' '8.2')
for PHPVER in "${PHPVERS[@]}"; do
	sudo apt-get install -y php$PHPVER libapache2-mod-php$PHPVER
	sudo apt-get install -y php$PHPVER-{fpm,curl,zip,intl,xmlrpc,soap,xml,gd,ldap,common,cli,mbstring,mysql,imagick,json,readline,tidy,redis,memcached,apcu,opcache,mongodb} 
done


for PHPVER in "${PHPVERS[@]}"; do
	# Set PHP ini
	sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/$PHPVER/fpm/php.ini
	sed -i 's/post_max_size =.*/post_max_size = 256M/' /etc/php/$PHPVER/fpm/php.ini
	sed -i 's/upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/$PHPVER/fpm/php.ini
	sed -i 's/;max_input_vars =.*/max_input_vars = 6000/' /etc/php/$PHPVER/fpm/php.ini

	sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/$PHPVER/apache2/php.ini
	sed -i 's/post_max_size =.*/post_max_size = 256M/' /etc/php/$PHPVER/apache2/php.ini
	sed -i 's/upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/$PHPVER/apache2/php.ini
	sed -i 's/;max_input_vars =.*/max_input_vars = 6000/' /etc/php/$PHPVER/apache2/php.ini

	sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/$PHPVER/cli/php.ini
	sed -i 's/post_max_size =.*/post_max_size = 256M/' /etc/php/$PHPVER/cli/php.ini
	sed -i 's/upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/$PHPVER/cli/php.ini
	sed -i 's/;max_input_vars =.*/max_input_vars = 6000/' /etc/php/$PHPVER/cli/php.ini
done

sudo a2enmod actions alias proxy_fcgi
sudo systemctl restart apache2
# systemctl reload apache2

