#!/bin/bash

MOODLE_HOME="/var/www/moodle/html" # moodle core folder
MOODLE_DATA="/mnt/mdl/data"  # moodle data folder
GIT_DIR="/var/www/moodle/git"      # git folder

MOODLE_BRANCH="MOODLE_39_STABLE"     # Moodle Branch
PLUGINS_GIT="https://github.com/AdrianoRuseler/mdlmooc-plugins.git"

TMP_DIR="/tmp"                       # temp folder
SYSUPGRADE=1                         # Perform system upgrade?
MDLUPGRADE=1                         # Moodle upgrade? 0-> just copy MDL foder
REPOREMOVE=1                         # Remove git repo?
SUBUPGRADE=1                         # submodule (plugins) update

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

echo "Check if git folder exists..."
if [ -d "$GIT_DIR" ]; then
  ### Take action if $GIT_DIR exists ###
  echo "Found git folder: ${GIT_DIR}"
else
   ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${GIT_DIR} not found. Can not continue, script for Update only!"
  echo "Is ${GIT_DIR} your GIT directory?"
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

echo "Check for free space in $GIT_DIR ..."
FREESPACE=$(df "$GIT_DIR" | awk 'NR==2 { print $4 }')
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
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -yq

echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y
fi


echo ""
echo "##--------------------------- GIT ------------------------------##"
cd $GIT_DIR


if [ -d "plugins" ]; then
  echo "Found moodle-plugins repository..."
  cd $GIT_DIR/plugins
  git clean -ffdx # This gets you in same state as fresh clone.
  git submodule update --init
  git pull
  git pull --recurse-submodules
    if [[ $SUBUPGRADE -ne 0 ]]; then
      git submodule update --remote # Plugins update
    fi
else
  git clone --depth=1 --recursive $PLUGINS_GIT plugins
  if [[ $? -ne 0 ]]; then
    echo "Error: git clone --recursive"
    echo "##------------------------ FAIL -------------------------##"
    exit 1
  fi
  cd $GIT_DIR/plugins
    if [[ $SUBUPGRADE -ne 0 ]]; then
      git submodule update --remote # Plugins update
    fi
fi

git status


echo ""
echo "##--------------------- DOWNLOADING MOODLE CORE FILES -------------------------##"
cd $GIT_DIR
if [ -d "core" ]; then
  echo "Found moodle-core repository..."
  cd $GIT_DIR/core
  git pull
else
  echo "Cloning moodle-core repository..."
  git clone --depth=1 --branch=$MOODLE_BRANCH https://github.com/moodle/moodle.git core
  if [[ $? -ne 0 ]]; then
    echo "Error: git clone moodle core!"
    echo "##------------------------ FAIL -------------------------##"
    exit 1
  fi
fi

cd $GIT_DIR/core
git status


echo ""
echo "##---------------------- MERGING MOODLE FILES -------------------------##"
echo "Merging core files and plugins to tmp dir..."

rsync -a $GIT_DIR/core/ $TMP_DIR/moodle
rsync -a $GIT_DIR/plugins/moodle/ $TMP_DIR/moodle
#rsync -a $GIT_DIR/plugins/climaintenance.html $MOODLE_DATA/climaintenance.html

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
sudo chown www-data:www-data -R $MOODLE_HOME

echo ""
echo "##------------------------ SUCCESS -------------------------##"
exit 0

fi


echo ""
echo "##------------------- MAINTENANCE MODE -------------------------##"

# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
if [[ $? -ne 0 ]]; then
  echo "Error: Activating Moodle Maintenance Mode!"
  rm -rf $TMP_DIR/moodle
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

sleep 30 # wait 30 secs


echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated!"


echo ""
echo "##----------------------- MOODLE UPDATE -------------------------##"
echo "Rsync page to display under maintenance... "
sudo rsync -a $GIT_DIR/plugins/climaintenance.html $MOODLE_DATA/climaintenance.html

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
sudo chown www-data:www-data -R $MOODLE_HOME

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive --allow-unstable
if [[ $? -ne 0 ]]; then # Error in upgrade script
  echo "Error in upgrade script..."
  if [ -d "$MOODLE_HOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
    sudo rm -rf $MOODLE_HOME                      # Remove new files
    sudo mv $MOODLE_HOME.$DAY.tmpbkp $MOODLE_HOME # restore old files
  fi
  echo "Disable the maintenance mode..."
  sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "purge Moodle cache..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "fix courses..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

echo "Removing temporary backup files..."
sudo rm -rf $MOODLE_HOME.$DAY.tmpbkp


echo ""
echo "##------------------------ SUCCESS -------------------------##"
exit 0
