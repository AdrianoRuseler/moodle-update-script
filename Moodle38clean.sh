#!/bin/bash

MOODLE_HOME="/var/www/html/moodle" # moodle core folder
MOODLE_DATA="/var/www/moodledata"  # moodle data folder
GIT_DIR="${HOME}/gitrepo38"            # git folder
TMP_DIR="/tmp"                       # temp folder
SYSUPGRADE=0                         # Perform system upgrade?
MDLUPGRADE=1                         # Moodle upgrade? 0-> just copy MDL foder
REPOREMOVE=1                         # Remove git repo? 

REQSPACE=524288 # Required free space: 512 Mb in kB
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

echo "##--------------------- SYSTEM INFO --------------------------##"
uname -a # Gets system info
echo ""
df -H # Gets disk usage info
echo ""
date # Gets date

echo ""
echo "##----------------------- FOLDER CHECK ------------------------##"

echo "Check if Moodle Home folder exists..."
if [ -d "$MOODLE_HOME" ]; then
  ### Take action if $MOODLE_HOME exists ###
  echo "Found Moodle Home folder: ${MOODLE_HOME}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${MOODLE_HOME} not found. Can not continue, script for Update only!"
  echo "Is ${MOODLE_HOME} your Moodle Home directory?"
  echo "##------------------------ FAIL -------------------------##"
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
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi


echo ""
echo "##----------------------- SPACE CHECK ------------------------##"


echo "Check for free space in $MOODLE_HOME ..."
FREESPACE=$(df "$MOODLE_HOME" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
  echo "NOT enough Space!!"
  echo "##------------------------ FAIL -------------------------##"
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
  echo "##------------------------ FAIL -------------------------##"
  exit 1
else
  echo "Enough Space!!"
fi


if [[ $SYSUPGRADE -ne 0 ]]; then
echo ""
echo "##----------------------- SYSTEM UPGRADE ------------------------##"
echo "Update and Upgrade System..."
sudo apt-get update 
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y
fi

echo ""
echo "##--------------------- DOWNLOADING FILES -------------------------##"

cd $TMP_DIR
wget https://download.moodle.org/download.php/direct/stable38/moodle-latest-38.tgz -O moodle-latest-38.tgz
if [[ $? -ne 0 ]]; then
  echo "Error: Download moodle-latest-38.tgz"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

wget https://download.moodle.org/download.php/direct/stable38/moodle-latest-38.tgz.md5 -O moodle-latest-38.tgz.md5
if [[ $? -ne 0 ]]; then
  echo "Error: Download moodle-latest-38.tgz.md5"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi


md5sum -c moodle-latest-38.tgz.md5
if [[ $? -ne 0 ]]; then
  echo "Error: md5sum -c moodle-latest-38.tgz.md5"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi



echo ""
echo "##------------------------ MOVING FILES -------------------------##"

echo "Extract moodle-latest-38.tgz..."
tar xzf moodle-latest-38.tgz 
if [[ $? -ne 0 ]]; then
  echo "Error: tar xzf moodle-latest-38.tgz"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

if [[ $MDLUPGRADE -eq 0 ]]; then
echo ""
echo "##------------------- MOODLE COPY MODE -------------------------##"

echo "Moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.$DAY.tmpbkp

echo "moving new files..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "Copying config file ..."
sudo cp $MOODLE_HOME.$DAY.tmpbkp/config.php $MOODLE_HOME
if [[ $? -ne 0 ]]; then
  echo "##---------------- NO CONFIG FILE FOUND! ----------------------##"
fi

echo "fixing file permissions..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown apache:apache -R $MOODLE_HOME

echo ""
echo "##------------------------ SUCCESS -------------------------##"
exit 0

fi

echo ""
echo "##------------------- MAINTENANCE MODE -------------------------##"

# echo "Activating Moodle Maintenance Mode in...";
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
if [[ $? -ne 0 ]]; then
  echo "Error: Activating Moodle Maintenance Mode!"
  rm -rf $TMP_DIR/moodle
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

sleep 30 # wait 30 secs

echo "Kill all user sessions..."
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated!"

echo ""
echo "##----------------------- MOODLE UPDATE -------------------------##"
echo "Rsync page to display under maintenance... "
sudo rsync -a $GIT_DIR/moodle38-plugins/climaintenance.html $MOODLE_DATA/climaintenance.html

echo "Moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.$DAY.tmpbkp

echo "moving new files..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "Copying config file ..."
sudo cp $MOODLE_HOME.$DAY.tmpbkp/config.php $MOODLE_HOME
if [[ $? -ne 0 ]]; then
  echo "Error: Copying config file!"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "fixing file permissions..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown apache:apache -R $MOODLE_HOME

echo "Upgrading Moodle Core started..."
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive --allow-unstable
if [[ $? -ne 0 ]]; then # Error in upgrade script
  echo "Error in upgrade script..."
  if [ -d "$MOODLE_HOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
    sudo rm -rf $MOODLE_HOME                      # Remove new files
    sudo mv $MOODLE_HOME.$DAY.tmpbkp $MOODLE_HOME # restore old files
  fi
  echo "Disable the maintenance mode..."
  sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "purge Moodle cache..."
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "fix courses..."
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "disable the maintenance mode..."
sudo -u apache /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

echo "Removing temporary backup files..."
sudo rm -rf $MOODLE_HOME.$DAY.tmpbkp



echo ""
echo "##------------------------ SUCCESS -------------------------##"
exit 0