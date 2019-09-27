#!/bin/bash

MOODLE_HOME="/var/www/html/moodle35"
MOODLE_DATA="/var/www/moodle35data"
TMP_DIR="/tmp"
REQSPACE=524288 # Required free space: 512 Mb in kB

echo "Check if Moodle Home folder exists..."
if [ -d "$MOODLE_HOME" ]; then
  ### Take action if $MOODLE_HOME exists ###
  echo "Found Moodle Home folder: ${MOODLE_HOME}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${MOODLE_HOME} not found. Can not continue, script for Update only!"
  echo "Is ${MOODLE_HOME} your Moodle Home directory?"
  exit 1
fi

echo "Check if Moodle Data folder exists..."
if [ -d "$MOODLE_DATA" ]; then
  ### Take action if $MOODLE_DATA exists ###
  echo "Found Moodle Data folder: ${MOODLE_DATA}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${MOODLE_DATA} not found. Can not continue, script for Update only!"
  echo "Is ${MOODLE_DATA} your Moodle Data directory?"
  exit 1
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

cd $TMP_DIR

echo "Download moodle-latest-35.tgz..."
wget https://download.moodle.org/download.php/direct/stable35/moodle-latest-35.tgz -O moodle-latest-35.tgz
if [[ $? -ne 0 ]] ; then
    exit 1
fi
echo "Download OK..."

echo "Download moodle-latest-35.tgz.md5..."
wget https://download.moodle.org/download.php/direct/stable35/moodle-latest-35.tgz.md5 -O moodle-latest-35.tgz.md5
if [[ $? -ne 0 ]] ; then
    exit 1
fi
echo "OK!"

echo "Check MD5 (128-bit) checksums..."
md5sum -c moodle-latest-35.tgz.md5
if [[ $? -ne 0 ]] ; then
    exit 1    
fi

echo "Extract moodle-latest-35.tgz..."
tar xzf moodle-latest-35.tgz
if [[ $? -ne 0 ]] ; then
    echo "Error: tar xzf moodle-latest-35.tgz"
    exit 1    
fi

echo "Clean files..."
rm -rf moodle-latest-35.tgz

# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
sleep 30 # wait 30 secs

echo "Kill all user sessions...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated...";

cd $MOODLE_DATA
echo "Download page to display under maintenance... "
sudo -u www-data wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/climaintenance.html -O climaintenance.html
cd $TMP_DIR

echo "moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.bkp

echo "moving new files ..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "copying config file ..."
sudo cp $MOODLE_HOME.bkp/config.php $MOODLE_HOME

echo "fixing file permissions ..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown www-data:www-data -R $MOODLE_HOME 

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive

echo "purge Moodle cache ..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

#echo "compress moodle backup directory ..."
#sudo tar -zcf $MOODLE_HOME.bkp.tar.gz $MOODLE_HOME.bkp
sudo rm -rf $MOODLE_HOME.bkp
