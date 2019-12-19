#!/bin/bash

WIKI_HOME="/var/www/html/openwiki" # wiki core folder
MEDIAWIKI_URL="https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.0.tar.gz"
MEDIAWIKI_FOLDER="mediawiki-1.34.0"
MEDIAWIKI_FILE="mediawiki-1.34.0.tar.gz"
TMP_DIR="/tmp"       # temp folder
DAY=$(date +\%Y-\%m-\%d-\%H.\%M) # gets date
REQSPACE=524288 # Required free space: 512 Mb in kB

echo "##--------------------- SYS INFO --------------------------##"
echo "System info:"
uname -a # Gets system info
date # Gets date

echo "##--------------------- FOLDER CHECK -----------------------##"

echo "Check if Wiki Home folder exists..."
if [ -d "$WIKI_HOME" ]; then
  ### Take action if $WIKI_HOME exists ###
  echo "Found Wiki Home folder: ${WIKI_HOME}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${WIKI_HOME} not found. Can not continue, script for Update only!"
  echo "Is ${WIKI_HOME} your Wiki Home directory?"
  echo "##---------------------  FAIL  ---------------------------##"
  exit 1
fi

echo "##--------------------- SPACE CHECK -----------------------##"

echo "Check for free space in $WIKI_HOME ..."
FREESPACE=$(df "$WIKI_HOME" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
  echo "NOT enough Space!!"
  echo "##---------------------  FAIL  ---------------------------##"
  exit 1
else
  echo "Enough Space!!"
fi

echo "##------------------ MEDIAWIKI DOWNLOAD ------------------##"

cd $TMP_DIR
wget $MEDIAWIKI_URL
if [[ $? -ne 0 ]]; then
  echo "Error: wget ${MEDIAWIKI_URL}"
  echo "##---------------------  FAIL  ---------------------------##"
  exit 1
fi


echo "Extract ${MEDIAWIKI_FILE}..."
tar xf $MEDIAWIKI_FILE
if [[ $? -ne 0 ]]; then
  echo "Error: tar xf ${MEDIAWIKI_FILE}"
  echo "##---------------------  FAIL  ---------------------------##"
  exit 1
fi



echo "##--------------------- Wiki Extensions --------------------------##"
# echo "https://www.mediawiki.org/wiki/Special:ExtensionDistributor"
cd $TMP_DIR
wget https://extdist.wmflabs.org/dist/extensions/Math-REL1_33-183fd5c.tar.gz
tar -xzf Math-REL1_33-183fd5c.tar.gz -C $MEDIAWIKI_FOLDER/extensions
rm Math-REL1_33-183fd5c.tar.gz

echo "##--------------------- Moving Files --------------------------##"
echo "Moving old files ..."
sudo mv $WIKI_HOME $WIKI_HOME.$DAY.tmpbkp

echo "moving new files..."
sudo mv $TMP_DIR/$MEDIAWIKI_FOLDER $WIKI_HOME

echo "fixing file permissions..."
sudo chown -R www-data:www-data $WIKI_HOME

echo "Copying config file ..."
sudo cp $WIKI_HOME.$DAY.tmpbkp/LocalSettings.php $WIKI_HOME

echo "Copying assets files ..."
sudo cp $WIKI_HOME.$DAY.tmpbkp/resources/assets/ARWiki.png $WIKI_HOME/resources/assets/
sudo cp $WIKI_HOME.$DAY.tmpbkp/resources/assets/favicon.ico $WIKI_HOME/resources/assets/

echo "##------------------ Wiki core update ------------------------##"
echo "Upgrading mediaiwki Core..."
sudo -u www-data /usr/bin/php $WIKI_HOME/maintenance/update.php --quick
if [[ $? -ne 0 ]]; then
  echo "Error: Upgrading mediaiwki Core!"
  if [ -d "$WIKI_HOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
    sudo rm -rf $WIKI_HOME                      # Remove new files
    sudo mv $WIKI_HOME.$DAY.tmpbkp $WIKI_HOME # restore old files
  fi
  echo "##---------------------  FAIL  ---------------------------##"
  exit 1
fi

echo "Removing temporary backup files..."
sudo rm -rf $WIKI_HOME.$DAY.tmpbkp 
sudo rm $TMP_DIR/$MEDIAWIKI_FILE
echo "##---------------------  SUCCESS  ---------------------------##"
exit 0


