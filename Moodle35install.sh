#!/bin/bash

# LAMP is assumed to be installed (Apache+PHP+MariaDB)
MOODLE_HOME="/var/www/html/moodle35" # moodle core folder
MOODLE_DATA="/var/www/moodle35data" # moodle data folder
GIT_DIR="${HOME}/gitrepo" # git folder
BKP_DIR="${HOME}/MDLBKPS" # moodle backup folder
TMP_DIR="/tmp" # temp folder
REQSPACE=524288 # Required free space: 512 Mb in kB
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)


echo "Check if Backup folder exists..."
if [ -d "$BKP_DIR" ]; then
echo "Found Backup folder: ${BKP_DIR}"
else
   sudo mkdir $BKP_DIR
   if [[ $? -ne 0 ]] ; then
      echo "Error: Could not create folder!"
       exit 1
   fi
fi

echo "Check if Moodle Home folder exists..."
if [ -d "$MOODLE_HOME" ]; then
  ### Take action if $MOODLE_HOME exists ###
  echo "Found Moodle Home folder: ${MOODLE_HOME}"
  echo "BackingUp existing files ..."

  sudo tar -zcf $BKP_DIR/moodlehome.$DAY.tar.gz $MOODLE_HOME
  if [[ $? -ne 0 ]] ; then
      echo "Error: Could not BackUp folder!"
      exit 1
   fi
   sudo rm -rf $MOODLE_HOME   
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Not Found: ${MOODLE_HOME}. Creating folder!"
fi

echo "Create Moodle Home folder..."
sudo mkdir $MOODLE_HOME
if [[ $? -ne 0 ]] ; then
      echo "Error: Could not create folder!"
      exit 1
fi

echo "Check if Moodle Data folder exists..."
if [ -d "$MOODLE_DATA" ]; then
  ### Take action if $MOODLE_DATA exists ###
  echo "Found Moodle Data folder: ${MOODLE_DATA}"
  sudo tar -zcf $BKP_DIR/moodledata.$DAY.tar.gz $MOODLE_DATA #
  if [[ $? -ne 0 ]] ; then
      echo "Error: Could not BackUp folder!"
      exit 1
   fi
   sudo rm -rf $MOODLE_DATA
fi

echo "Creating folder ${MOODLE_DATA}...!"
sudo mkdir $MOODLE_DATA
    if [[ $? -ne 0 ]] ; then
      echo "Error: Could not create folder!"
      exit 1
    fi

echo "Check if git folder exists..."
if [ -d "$GIT_DIR" ]; then
  ### Take action if $GIT_DIR exists ###
  echo "Found git folder: ${GIT_DIR}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Not Found: ${GIT_DIR}. Creating folder!"
  sudo mkdir $GIT_DIR
    if [[ $? -ne 0 ]] ; then
      echo "Error: Could not create folder!"
      exit 1
    fi
fi

echo "Check for free space in $MOODLE_HOME ..."
FREESPACE=$(df "$MOODLE_HOME" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
    echo "NOT enough Space!!"
    exit 1
else
    echo "Enough Space!!"
fi

echo "Check for free space in $GIT_DIR ..."
FREESPACE=$(df "$GIT_DIR" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
    echo "NOT enough Space!!"
    exit 1
else
    echo "Enough Space!!"
fi

echo "Check for free space in $TMP_DIR ..."
FREESPACE=$(df "$TMP_DIR" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
    echo "NOT enough Space!!"
    exit 1
else
    echo "Enough Space!!"
fi

echo "Update and Upgrade System..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Install some sys utils..."
sudo apt-get install -y git p7zip-full


cd $GIT_DIR
if [ -d "moodle35-plugins" ]; then
    cd $GIT_DIR/moodle35-plugins
    git pull --recurse-submodules    
else
    git clone --recursive https://github.com/AdrianoRuseler/moodle35-plugins.git
    if [[ $? -ne 0 ]] ; then
      echo "Error: git clone --recursive https://github.com/AdrianoRuseler/moodle35-plugins.git"
      exit 1
    fi
    cd $GIT_DIR/moodle35-plugins
    git pull --recurse-submodules
fi

echo "Get git status..."
git status

echo "Rsync moodle folder from moodle-plugins repo..."
rsync -a $GIT_DIR/moodle35-plugins/moodle/ $TMP_DIR/moodle
if [[ $? -ne 0 ]] ; then
    echo "Error: Rsync moodle folder from moodle-plugins repo"
    exit 1    
fi

echo "Extract moodle-latest-35.tgz..."
tar xzf $GIT_DIR/moodle35-plugins/moodle-latest-35.tgz -C $TMP_DIR
if [[ $? -ne 0 ]] ; then
    echo "Error: tar xzf moodle-latest-35.tgz"
    exit 1    
fi

echo "moving moodle core files..."
sudo mv $TMP_DIR/moodle/* $MOODLE_HOME
if [[ $? -ne 0 ]] ; then
    echo "Error: Cloud not move moodle core files"
    exit 1    
fi

echo "download GeoLite2-City..."
cd $TMP_DIR
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz
gzip -d GeoLite2-City.mmdb.gz
sudo mkdir $MOODLE_DATA/geoip
sudo mv GeoLite2-City.mmdb $MOODLE_DATA/geoip/GeoLite2-City.mmdb

echo "fixing file permissions..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown www-data:www-data -R $MOODLE_HOME 
sudo chown www-data:www-data -R $MOODLE_DATA

echo "Install php extensions..."
sudo apt-get install -y php-curl php-zip php-intl php-xmlrpc php-soap php-xml php-gd php-ldap php-common php-cli php-mbstring php-mysql php-imagick php-pdo php-json php-readline php-tidy php-xsl
# Cache related 
sudo apt-get install -y php-redis php-memcached php-apcu php-opcache 

echo "Restart apache server..."
sudo service apache2 restart

echo "Add locales pt_BR, en_US, es_ES, de_DE, fr_FR, pt_PT..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* es_ES.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* de_DE.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* fr_FR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* pt_PT.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "To use spell-checking within the editor, you MUST have aspell 0.50 or later installed on your server..."
sudo apt-get install -y aspell dictionaries-common libaspell15 aspell-de aspell-es aspell-fr aspell-en aspell-pt-br aspell-pt-pt aspell-doc spellutils

echo "Install python..."
sudo apt-get install -y python2 python3

echo "To be able to generate graphics from DOT files, you must have installed the dot executable..."
sudo apt-get install -y graphviz

echo "Install maxima, gcc and gnuplot (Stack question type for Moodle) ..."
sudo apt-get install -y maxima gcc gnuplot

echo "Install Moodle Core..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/install.php






