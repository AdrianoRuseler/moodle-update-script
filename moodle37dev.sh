#!/bin/bash

MOODLE_HOME="/var/www/html/moodle37dev"          # moodle core folder
MOODLE_DATA="/var/www/moodle37devdata"           # moodle data folder
GIT_DIR="/home/usuarios/pessoas/ruseler/gitrepo" # git folder
TMP_DIR="/tmp"                                   # temp folder

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

echo "Check if git folder exists..."
if [ -d "$GIT_DIR" ]; then
  ### Take action if $GIT_DIR exists ###
  echo "Found git folder: ${GIT_DIR}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "${GIT_DIR} not found!"
  echo "Create GIT directory: ${GIT_DIR}"
  sudo mkdir $GIT_DIR
  if [[ $? -ne 0 ]]; then
    echo "Error: Could not create GIT directory: ${GIT_DIR}"
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

cd $GIT_DIR
rm output.log
if [ -d "moodle37-plugins" ]; then
  cd $GIT_DIR/moodle37-plugins
 # git pull --recurse-submodules
 # git status
else
  git clone --recursive https://github.com/AdrianoRuseler/moodle37-plugins.git
  if [[ $? -ne 0 ]]; then
    echo "Error: git clone --recursive https://github.com/AdrianoRuseler/moodle37-plugins.git"
    exit 1
  fi
  cd $GIT_DIR/moodle37-plugins
 # git pull --recurse-submodules
fi

# pull all changes for the submodules
git submodule update --remote | tee -a $GIT_DIR/output.log

# pull all changes in the repo including changes in the submodules
git pull --recurse-submodules | tee -a $GIT_DIR/output.log

git status | tee -a $GIT_DIR/output.log

cd $GIT_DIR/moodle37-plugins/
rm moodle-latest-37.tgz.md5
wget https://download.moodle.org/download.php/direct/stable37/moodle-latest-37.tgz.md5 -O moodle-latest-37.tgz.md5 | tee -a $GIT_DIR/output.log
md5sum -c $GIT_DIR/moodle37-plugins/moodle-latest-37.tgz.md5 | tee -a $GIT_DIR/output.log
if [[ $? -ne 0 ]]; then
  echo "Updated moodle-latest-37 version! Download new version..." | tee -a $GIT_DIR/output.log
  rm moodle-latest-37.tgz
  wget https://download.moodle.org/download.php/direct/stable37/moodle-latest-37.tgz -O moodle-latest-37.tgz | tee -a $GIT_DIR/output.log
  if [[ $? -ne 0 ]]; then
    sudo /usr/bin/php $GIT_DIR/failmail.php
    exit 1
  fi
else
  echo "Same moodle-latest-37 version!"
fi

echo "Rsync moodle folder from moodle37-plugins repo..."
rsync -a $GIT_DIR/moodle37-plugins/moodle/ $TMP_DIR/moodle

echo "Extract moodle-latest-37.tgz..."
tar xzf $GIT_DIR/moodle37-plugins/moodle-latest-37.tgz -C $TMP_DIR
if [[ $? -ne 0 ]]; then
  echo "Error: tar xzf moodle-latest-37.tgz"
  exit 1
fi

# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1 | tee -a $GIT_DIR/output.log
if [[ $? -ne 0 ]]; then
  echo "Error: Activating Moodle Maintenance Mode!"
  rm -rf $TMP_DIR/moodle
  sudo /usr/bin/php $GIT_DIR/failmail.php
  exit 1
fi

sleep 30 # wait 30 secs

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php | tee -a $GIT_DIR/output.log

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated!"

echo "Rsync page to display under maintenance... "
sudo rsync -a $GIT_DIR/moodle37-plugins/climaintenance.html $MOODLE_DATA/climaintenance.html

echo "Moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.$DAY.tmpbkp

echo "moving new files..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "Copying config file ..."
sudo cp $MOODLE_HOME.$DAY.tmpbkp/config.php $MOODLE_HOME
if [[ $? -ne 0 ]]; then
  echo "Error: Copying config file!"
  sudo /usr/bin/php $GIT_DIR/failmail.php
  exit 1
fi

echo "fixing file permissions..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown www-data:www-data -R $MOODLE_HOME

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive --lang=en | tee -a $GIT_DIR/output.log
if [[ $? -ne 0 ]]; then # Error in upgrade script
  echo "Error in upgrade script..."
  if [ -d "$MOODLE_HOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
    sudo rm -rf $MOODLE_HOME                      # Remove new files
    sudo mv $MOODLE_HOME.$DAY.tmpbkp $MOODLE_HOME # restore old files
  fi
  echo "Disable the maintenance mode..."
  sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable | tee -a $GIT_DIR/output.log

  sudo /usr/bin/php $GIT_DIR/failmail.php
  exit 1
fi

echo "purge Moodle cache..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php | tee -a $GIT_DIR/output.log

echo "fix courses..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix | tee -a $GIT_DIR/output.log

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable | tee -a $GIT_DIR/output.log

echo "Removing temporary backup files..."
sudo rm -rf $MOODLE_HOME.$DAY.tmpbkp

echo "Send success mail.. "
sudo /usr/bin/php $GIT_DIR/successmail.php

exit 0