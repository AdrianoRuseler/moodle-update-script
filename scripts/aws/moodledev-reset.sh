#!/bin/bash

MOODLE_HOME="/var/www/moodle/html" # moodle core folder
MOODLE_DATA="/mnt/mdl/data"  # moodle data folder
GIT_DIR="/var/www/moodle/git"      # git folder

MOODLE_BRANCH="master"     # Moodle Branch
PLUGINS_GIT="https://github.com/AdrianoRuseler/mdlmooc-plugins.git"

PGDBNAME=$(pwgen -s 10 -1 -v -A -0) # DB name
PGDBUSER=$(pwgen -s 10 -1 -v -A -0) # User name
PGDBPASS=$(pwgen -s 14 1) # Password for db user



TMP_DIR="/tmp"                       # temp folder
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


echo ""
echo "##--------------------------- GIT ------------------------------##"
cd $GIT_DIR


if [[ $REPOREMOVE -eq 1 ]]; then
echo ""
echo "##------------------- DELETE GIT REPOS -------------------------##"

rm -rf $GIT_DIR/plugins
rm -rf $GIT_DIR/core

fi

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
echo "##---------------------- GENERATES NEW DB -------------------------##"
echo ""
PGDBNAME=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon db name
PGDBUSER=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon user name
PGDBPASS=$(pwgen -s 14 1) # Generates ramdon password for db user
echo "DB Name: $PGDBNAME"
echo "DB User: $PGDBUSER"
echo "DB Pass: $PGDBPASS"
echo ""

touch /tmp/createdbuser.sql
echo $'CREATE DATABASE '${PGDBNAME}$';' >> /tmp/createdbuser.sql
echo $'CREATE USER '${PGDBUSER}$' WITH PASSWORD \''${PGDBPASS}$'\';' >> /tmp/createdbuser.sql
echo $'GRANT ALL PRIVILEGES ON DATABASE '${PGDBNAME}$' TO '${PGDBUSER}$';' >> /tmp/createdbuser.sql
cat /tmp/createdbuser.sql

echo ""
sudo -i -u postgres psql -f /tmp/createdbuser.sql
rm /tmp/createdbuser.sql


echo ""
echo "##---------------------- MERGING MOODLE FILES -------------------------##"
echo "Merging core files and plugins to tmp dir..."
GIT_DIR='/var/www/moodledev/git'
TMP_DIR='/tmp'
MOODLE_HOME='/var/www/moodledev/html'
MOODLE_DATA='/mnt/nvme1n1p1/datadev'

rsync -a $GIT_DIR/core/ $TMP_DIR/moodle
rsync -a $GIT_DIR/plugins/moodle/ $TMP_DIR/moodle
rsync -a $GIT_DIR/plugins/climaintenance.html $MOODLE_DATA/climaintenance.html

mv $TMP_DIR/moodle/* $MOODLE_HOME


cp /var/www/moodle/html/config.php $MOODLE_HOME/config.php 

# Copy moodle config file
cp /var/www/moodle/git/plugins/scripts/test/config-dist.php /var/www/moodle/html/config.php 
sed -i 's/mydbname/'"$PGDBNAME"'/' /var/www/moodle/html/config.php # Configure mydbname
sed -i 's/mydbuser/'"$PGDBUSER"'/' /var/www/moodle/html/config.php # Configure mydbuser
sed -i 's/mydbpass/'"$PGDBPASS"'/' /var/www/moodle/html/config.php # Configure mydbpass
sed -i 's/mytesturl/https:\/\/'"$PUBHOST"'/' /var/www/moodle/html/config.php # Configure url

cp /var/www/moodle/git/plugins/scripts/test/defaults-dist.php /var/www/moodle/html/local/defaults.php 
sed -i 's/mytesturl/'"$PUBHOST"'/' /var/www/moodle/html/local/defaults.php 
MDLADMPASS=$(pwgen -s 14 1) # Generates ramdon password for Moodle Admin
sed -i 's/myadmpass/'"$MDLADMPASS"'/' /var/www/moodle/html/local/defaults.php # Set password in file



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
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive
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
