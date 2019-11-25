#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update 
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef


echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Add locales pt_BR, en_US, es_ES, de_DE, fr_FR, pt_PT..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* es_ES.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* de_DE.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* fr_FR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* pt_PT.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "Install some sys utils..."
sudo apt-get install -y git p7zip-full

echo "Install python..."
sudo apt-get install -y python3

echo "Install php extensions..."
sudo apt-get install -y php-curl php-zip php-intl php-xmlrpc php-soap php-xml php-gd php-ldap php-common php-cli php-mbstring php-mysql php-imagick php-pdo php-json php-readline php-tidy php-xsl
# Cache related
sudo apt-get install -y php-redis php-memcached php-apcu php-opcache

echo "Restart apache server..."
sudo service apache2 restart

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

sudo apt-get install -y texlive
  
# echo "Install maxima, gcc and gnuplot (Stack question type for Moodle) ..."
# sudo apt-get install -y maxima gcc gnuplot
