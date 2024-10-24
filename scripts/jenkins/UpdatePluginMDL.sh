#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then
	export "$(grep -v '^#' .env | xargs)"
fi

# export LOCALSITENAME="oficina"
# export PLGREPO="https://github.com/AdrianoRuseler/moodle311-plugins.git"
# export PLGBRANCH="main"
# export PLGPATH="mod/example"
# export PHPVER="php7.4"

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
	echo "LOCALSITENAME is not set or is set to the empty string!"
	echo "Choose site to use:"
	ls /etc/apache2/sites-enabled/
	echo "export LOCALSITEFOLDER="
else
	echo "LOCALSITENAME has the value: $LOCALSITENAME"
fi

ENVFILE='.'${LOCALSITENAME}'.env'
#SCRIPTDIR=$(pwd)
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export "$(grep -v '^#' $ENVFILE | xargs)"
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
#	rm $ENVFILE
fi

echo ""
echo "##------------ SYSTEM INFO -----------------##"
uname -a # Gets system info
echo ""
df -H # Gets disk usage info
echo ""
apache2 -v # Gets apache version
echo ""

# PHP version to use
if [[ ! -v PHPVER ]] || [[ -z "$PHPVER" ]]; then
	echo "PHPVER is not set or is set to the empty string!"
	PHPVER='php' # Uses default version
else
	echo "PHPVER has the value: $PHPVER"
fi

# Verifies if PHPVER is installed
if ! [ -x "$(command -v $PHPVER)" ]; then
	echo "Error: $PHPVER is not installed."
	exit 1
else
	sudo -u www-data /usr/bin/$PHPVER -version # Gets php version
	echo ""
fi

echo "##------------ MDL INFO -----------------##"

# Verify for MDLHOME and MDLDATA
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]] || [[ ! -v MDLDATA ]] || [[ -z "$MDLDATA" ]]; then
	echo "MDLHOME or MDLDATA is not set or is set to the empty string!"
	exit 1
else
	echo "MDLHOME has the value: $MDLHOME"
	echo "MDLDATA has the value: $MDLDATA"
fi

# Verify if folder exists
if [[ -d "$MDLHOME" ]] && [[ -d "$MDLDATA" ]]; then
	echo "$MDLHOME and $MDLDATA exists on your filesystem."
else
	echo "$MDLHOME or $MDLDATA NOT exists on your filesystem."
	exit 1
fi

# Verify for plugin path
if [[ ! -v PLGPATH ]] || [[ -z "$PLGPATH" ]]; then
	echo "PLGPATH is not set or is set to the empty string"
	exit 1
else
	echo "PLGPATH has the value: $PLGPATH"
fi

echo "Check for free space in $MDLHOME ..."
REQSPACE=524288 # Required free space: 512 Mb in kB
FREESPACE=$(df "$MDLHOME" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
	echo "NOT enough Space!!"
	echo "##------------------------ FAIL -------------------------##"
	exit 1
else
	echo "Enough Space!!"
fi

# Clone git repository
MDLPLGS=$LOCALSITENAME'mdlplg'

# Verify for Moodle Branch
if [[ ! -v PLGREPO ]] || [[ -z "$PLGREPO" ]]; then
	echo "PLGREPO is not set or is set to the empty string"
else
	echo "PLGREPO has the value: $PLGREPO"
	# Verify for Moodle Repository
	if [[ ! -v PLGBRANCH ]] || [[ -z "$PLGBRANCH" ]]; then
		echo "PLGBRANCH is not set or is set to the empty string"
		export PLGBRANCH="main"
	else
		echo "PLGBRANCH has the value: $PLGBRANCH"
	fi
	cd /tmp || exit
	git clone --depth=1 --recursive --branch=$PLGBRANCH $PLGREPO $MDLPLGS
	#sudo rsync -a /tmp/$MDLPLGS/moodle/* /tmp/$MDLCORE/
	#rm -rf /tmp/$MDLPLGS
fi

echo "stop cron..."
sudo service cron stop

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/kill_all_sessions.php

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --enable

echo ""
echo "##----------------------- MOODLE UPDATE -------------------------##"
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

echo "Copy moodle html files ..."
sudo cp $MDLHOME $MDLHOME.$DAY.tmpbkp

ls -l $MDLHOME/$PLGPATH
echo "Delete plugin folder..."
rm -rf "${MDLHOME:?}/$PLGPATH"


echo "Copy plugin files ..."
sudo rsync -a /tmp/$MDLPLGS/* $MDLHOME/$PLGPATH/

echo "Delete plugin tmp folder..."
rm -rf /tmp/$MDLPLGS

echo "fixing file permissions..."
sudo chmod 740 $MDLHOME/admin/cli/cron.php
sudo chown -R root $MDLHOME
sudo chmod -R 0755 $MDLHOME

ls -l $MDLHOME/$PLGPATH

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/upgrade.php --non-interactive --allow-unstable
if [[ $? -ne 0 ]]; then # Error in upgrade script
	echo "Error in upgrade script..."
	if [ -d "$MDLHOME.$DAY.tmpbkp" ]; then # If exists
		echo "restoring old files..."
		sudo rm -rf $MDLHOME                  # Remove new files
		sudo mv $MDLHOME.$DAY.tmpbkp $MDLHOME # restore old files
	fi
	echo "Disable the maintenance mode..."
	sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --disable
	echo "##------------------------ FAIL -------------------------##"
	echo "start cron..."
	sudo service cron start
	exit 1
fi

echo "Removing temporary backup files..."
cd $MDLHOME || exit
cd ..
ls -l
sudo rm -rf $MDLHOME.$DAY.tmpbkp

echo "Disable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --disable

echo "start cron..."
sudo service cron start
