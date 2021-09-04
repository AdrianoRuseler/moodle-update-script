#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update 
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef


echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Add locales pt_BR, en_US, es_ES, pt_PT..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_AU.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* es_ES.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* pt_PT.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "Set timezone and locale..." 
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot

echo "Install some sys utils..."
sudo apt-get install -y git p7zip-full

echo "Install python..."
sudo apt-get install -y python3

echo "Install php7.4 for apache..."
sudo apt-get install apache2 php7.4 libapache2-mod-php7.4

echo "Install php7.4 extensions..."
sudo apt-get install -y php7.4-curl php7.4-zip php7.4-intl php7.4-xmlrpc php7.4-soap php7.4-xml php7.4-gd php7.4-ldap php7.4-common php7.4-cli php7.4-mbstring php7.4-mysql php7.4-imagick php7.4-json php7.4-readline php7.4-tidy

# Cache related
sudo apt-get install -y php7.4-redis php7.4-memcached php7.4-apcu php7.4-opcache

echo "Restart apache server..."
sudo service apache2 restart

# Set PHP ini
sed -i 's/memory_limit =.*/memory_limit = 512M/' /etc/php/7.4/apache2/php.ini
sed -i 's/post_max_size =.*/post_max_size = 128M/' /etc/php/7.4/apache2/php.ini
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 128M/' /etc/php/7.4/apache2/php.ini
sed -i 's/;max_input_vars =.*/max_input_vars = 5000/' /etc/php/7.4/apache2/php.ini
systemctl reload apache2


# Select php version
# sudo update-alternatives --config php

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "Install pdftoppm poppler-utils - Poppler is a PDF rendering library based on the xpdf-3.0 code base."
sudo apt-get install poppler-utils

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

#echo "Install TeX..."
#sudo apt-get install -y texlive imagemagick

#echo "Install Universal Office Converter..."
#sudo apt-get install -y unoconv
#sudo chown www-data /var/www

# echo "Install maxima, gcc and gnuplot (Stack question type for Moodle) ..."
# sudo apt-get install -y maxima gcc gnuplot
