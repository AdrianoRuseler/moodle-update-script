#!/bin/bash

MOODLE_HOME="/var/www/html/moodle35" # moodle core folder
MOODLE_DATA="/var/www/moodle35data" # moodle data folder
GIT_DIR="${HOME}/gitrepo" # git folder
TMP_DIR="/tmp" # temp folder
REQSPACE=524288 # Required free space: 512 Mb in kB

DAY=$(date +\%Y-\%m-\%d-\%H.\%M)


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


if [ -d "$TMP_DIR/moodle" ]; then
   echo "Remove moodle tmp folder!"
   sudo rm -rf $TMP_DIR/moodle      
fi

echo "Rsync moodle folder from moodle-plugins repo..."
sudo rsync -a $GIT_DIR/moodle35-plugins/moodle/ $TMP_DIR/moodle
if [[ $? -ne 0 ]] ; then
    echo "Error: Rsync moodle folder from moodle35-plugins repo"
    exit 1    
fi

echo "Extract moodle-latest-35.tgz..."
tar xzf $GIT_DIR/moodle35-plugins/moodle-latest-35.tgz -C $TMP_DIR
if [[ $? -ne 0 ]] ; then
    echo "Error: tar xzf moodle-latest-35.tgz"
    exit 1    
fi


# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
if [[ $? -ne 0 ]] ; then
    echo "Error: Activating Moodle Maintenance Mode!"
    rm -rf $TMP_DIR/moodle
    exit 1
fi
sleep 30 # wait 30 secs

echo "Kill all user sessions...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated!!";

echo "Rsync page to display under maintenance... "
sudo rsync -a $GIT_DIR/moodle35-plugins/climaintenance.html  $MOODLE_DATA/climaintenance.html

echo "Moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.$DAY.tmpbkp

echo "Moving new files ..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "Copying config file ..."
sudo cp $MOODLE_HOME.$DAY.tmpbkp/config.php $MOODLE_HOME
if [[ $? -ne 0 ]] ; then
    echo "Error: Copying config file!"
    exit 1
fi

echo "Fixing file permissions ..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown www-data:www-data -R $MOODLE_HOME 

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive --lang=en 
if [[ $? -ne 0 ]] ; then # Error in upgrade script
    echo "Error in upgrade script..."
    if [ -d "$MOODLE_HOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
       sudo rm -rf $MOODLE_HOME # Remove new files
       sudo mv $MOODLE_HOME.$DAY.tmpbkp $MOODLE_HOME # restore old files
    fi
    echo "Disable the maintenance mode..."
    sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable
    exit 1    
fi

echo "Purge Moodle cache ..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "Fix courses..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "Disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

echo "Removing temporary backup files..."
sudo rm -rf $MOODLE_HOME.$DAY.tmpbkp
