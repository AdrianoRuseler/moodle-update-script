#!/bin/bash

MOODLE_HOME="/var/www/html/moodle35"
MOODLE_DATA="/var/www/moodle35data"
GIT_DIR="/home/archive/gitrepo"
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

echo "Check if Moodle Home folder exists..."
if [ -d "$GIT_DIR" ]; then
  ### Take action if $GIT_DIR exists ###
  echo "Found Moodle Home folder: ${GIT_DIR}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${GIT_DIR} not found. Can not continue, script for Update only!"
  echo "Is ${GIT_DIR} your GIT directory?"
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
if [ -d "moodle35-plugins" ]; then
   cd moodle35-plugins/moodle
   git submodule foreach git pull
else
   git clone https://github.com/AdrianoRuseler/moodle35-plugins.git
    if [[ $? -ne 0 ]] ; then
      echo "Error: git clone https://github.com/AdrianoRuseler/moodle35-plugins.git"
      exit 1
  fi
  cd moodle35-plugins
  git submodule update --init --recursive
fi

# git clone -b MOODLE_35_STABLE https://github.com/moodle/moodle.git
cd $GIT_DIR
if [ -d "moodle" ]; then
   cd moodle
   git pull
else
   git clone -b MOODLE_35_STABLE https://github.com/moodle/moodle.git
    if [[ $? -ne 0 ]] ; then
      echo "Error: git clone -b MOODLE_35_STABLE https://github.com/moodle/moodle.git"
      exit 1
  fi
fi


# TODO
exit 0
cd ..
echo "Copy moodle folder from moodle-plugins repo..."
cp $GIT_DIR/moodle35-plugins/moodle $TMP_DIR/moodle



echo "Clean files..."
rm -rf moodle-latest-35.tgz moodle35-plugins moodle-latest-35.tgz.md5

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
echo "Moodle Maintenance Mode Activated...";

cd $MOODLE_DATA
echo "Download page to display under maintenance... "
sudo -u www-data wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/climaintenance.html -O climaintenance.html
cd $TMP_DIR

echo "Moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.tmpbkp

echo "Moving new files ..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "Copying config file ..."
sudo cp $MOODLE_HOME.tmpbkp/config.php $MOODLE_HOME
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
    if [ -d "$MOODLE_HOME.tmpbkp" ]; then # If exists
    echo "restoring old files..."
       sudo rm -rf $MOODLE_HOME # Remove new files
       sudo mv $MOODLE_HOME.tmpbkp $MOODLE_HOME # restore old files
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

#echo "compress moodle backup directory ..."
#sudo tar -zcf $MOODLE_HOME.tmpbkp.tar.gz $MOODLE_HOME.tmpbkp
echo "Removing temporary backup files..."
sudo rm -rf $MOODLE_HOME.tmpbkp
