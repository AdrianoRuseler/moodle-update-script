#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then	
	export $(grep -v '^#' .env | xargs)
fi

# export LOCALSITENAME="oficina"
# export MDLBRANCH="MOODLE_311_STABLE"
# export MDLREPO="https://github.com/moodle/moodle.git"
# export PLGBRANCH="main"
# export PLGREPO="https://github.com/AdrianoRuseler/moodle311-plugins.git"

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
SCRIPTDIR=$(pwd)
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
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
date # Gets date
echo ""

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

# Verify for Moodle Branch
if [[ ! -v MDLBRANCH ]] || [[ -z "$MDLBRANCH" ]]; then
    echo "MDLBRANCH is not set or is set to the empty string"
    exit 1
else
    echo "MDLBRANCH has the value: $MDLBRANCH"
fi

# Verify for Moodle Repository
if [[ ! -v MDLREPO ]] || [[ -z "$MDLREPO" ]]; then
    echo "MDLREPO is not set or is set to the empty string"
	exit 1
else
    echo "MDLREPO has the value: $MDLREPO"
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
cd /tmp
git clone --depth=1 --branch=$MDLBRANCH $MDLREPO mdlcore

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
	cd /tmp
	git clone --depth=1 --recursive --branch=$PLGBRANCH $PLGREPO mdlplugins
	sudo rsync -a /tmp/mdlplugins/moodle/* /tmp/mdlcore/
	rm -rf /tmp/mdlplugins
fi

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

echo "CLI purge Moodle cache..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/purge_caches.php

echo "CLI fix_course_sequence..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "CLI fix_deleted_users..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_deleted_users.php

echo "CLI fix_orphaned_calendar_events..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_orphaned_calendar_events.php

echo "CLI fix_orphaned_question_categories..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_orphaned_question_categories.php


echo ""
echo "##----------------------- MOODLE UPDATE -------------------------##"
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

echo "Moving old files ..."
sudo mv $MDLHOME $MDLHOME.$DAY.tmpbkp
mkdir $MDLHOME

echo "moving new files..."
sudo mv /tmp/mdlcore/* $MDLHOME
rm -rf /tmp/mdlcore

echo "Copying config file ..."
sudo cp $MDLHOME.$DAY.tmpbkp/config.php $MDLHOME


echo "fixing file permissions..."
sudo chmod 740 $MDLHOME/admin/cli/cron.php
sudo chown -R root $MDLHOME
sudo chmod -R 0755 $MDLHOME


echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/upgrade.php --non-interactive --allow-unstable
if [[ $? -ne 0 ]]; then # Error in upgrade script
  echo "Error in upgrade script..."
  if [ -d "$MDLHOME.$DAY.tmpbkp" ]; then # If exists
    echo "restoring old files..."
    sudo rm -rf $MDLHOME                      # Remove new files
    sudo mv $MDLHOME.$DAY.tmpbkp $MDLHOME # restore old files
  fi
  echo "Disable the maintenance mode..."
  sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "Removing temporary backup files..."
cd $MDLHOME
cd ..
ls -l
sudo rm -rf $MDLHOME.$DAY.tmpbkp

echo "Update Moodle site name:"
cd $MDLHOME
mdlrelease=$(moosh -n config-get core release)
moosh -n course-config-set course 1 fullname "Moodle $mdlrelease"
moosh -n course-config-set course 1 shortname "Moodle $mdlrelease"

echo "Disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable
