#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then
	export $(grep -v '^#' .env | xargs)
fi

# export LOCALSITENAME="mdl42"
# export MDLBRANCH="MOODLE_404_STABLE"
# export MDLREPO="https://github.com/moodle/moodle.git"
# export PLGBRANCH="main"
# export PLGREPO="https://github.com/AdrianoRuseler/moodle404-plugins.git"
# export CHECKOUTID="2e5460853080854ec62dece9601206d10d207b62"
# export PHPVER="php8.3"

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
# SCRIPTDIR=$(pwd)
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
apache2 -v # Gets apache version
echo ""
php -version # Gets php version
echo ""
mariadb --version # Gets mariadb version
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

# Verify if folder and config.php exists
if [[ -d "$MDLHOME" ]] && [[ -d "$MDLDATA" ]]; then
	echo "$MDLHOME and $MDLDATA exists on your filesystem."
	if [ -f "$MDLHOME/config.php" ]; then
		echo "$MDLHOME/config.php exists!"
	else
		echo "$MDLHOME/config.php does not exist!"
		exit 1
	fi
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

# Verify for Moodle DB name
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]]; then
	echo "DBNAME is not set or is set to the empty string"
	exit 1
else
	echo "DBNAME has the value: $DBNAME"
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
MDLCORE=$LOCALSITENAME'mdlcore'
MDLPLGS=$LOCALSITENAME'mdlplugins'

cd /tmp || exit

echo "Check if $MDLCORE folder exists..."
if [ -d "$MDLCORE" ]; then
	echo "Folder exists, so remove it..."
	rm -rf $MDLCORE
fi

echo "Cloning repository from $MDLREPO..."
git clone --depth=1 --branch=$MDLBRANCH $MDLREPO $MDLCORE >/tmp/git_clone_error.log

# Check if clone was successful
if [ $? -eq 0 ]; then
    echo "✓ Successfully cloned repository to '$MDLCORE'"

    # Additional verification: check if .git directory exists
    if [ -d "$MDLCORE/.git" ]; then
        echo "✓ Git repository verification successful"
        
        # Show repository information
        echo "Repository information:"
        cd "$MDLCORE" || exit
        git status
    else
        echo "Error: Cloned directory exists but is not a valid Git repository"
        exit 1
    fi
else
    echo "Error: Failed to clone repository"
    echo "Error details:"
    cat /tmp/git_clone_error.log
    exit 1
fi

# Verify for Moodle Plugins
cd /tmp || exit
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
	echo "Check if $MDLPLGS folder exists..."
	if [ -d "$MDLPLGS" ]; then
		echo "Folder exists, so remove it..."
		rm -rf "$MDLPLGS"
	fi

	if [[ ! -v CHECKOUTID ]] || [[ -z "$CHECKOUTID" ]]; then
		echo "CHECKOUTID is not set or is set to the empty string!"
		git clone --depth=1 --recursive --branch=$PLGBRANCH $PLGREPO $MDLPLGS
	else
		git clone --branch=$PLGBRANCH $PLGREPO $MDLPLGS
		cd $MDLPLGS || exit
		if git cat-file -e $CHECKOUTID 2>/dev/null; then
			echo "Exists CheckOut: $CHECKOUTID"
			git -c advice.detachedHead=false checkout $CHECKOUTID
			git submodule sync
			git submodule update --init
			if [ -d "moodle/mod/hvp" ]; then
				echo "mod/hvp Exists! So do something..."
				cd moodle/mod/hvp || return
				git submodule update --init
			else
				echo "mod/hvp dont exists!"
			fi

		else
			echo "Missing CheckOut: $CHECKOUTID"
		fi
		cd /tmp || exit
	fi

	sudo rsync -a /tmp/$MDLPLGS/moodle/* /tmp/$MDLCORE/
	rm -rf /tmp/$MDLPLGS
fi

echo "stop cron..."
sudo service cron stop

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/kill_all_sessions.php

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --enable

echo "CLI purge Moodle cache..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/purge_caches.php

echo "CLI fix_course_sequence..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "CLI fix_deleted_users..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_deleted_users.php

echo "CLI fix_orphaned_calendar_events..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_orphaned_calendar_events.php

echo "CLI fix_orphaned_question_categories..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_orphaned_question_categories.php

echo ""
echo "##----------------------- MOODLE UPDATE -------------------------##"
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

echo "Database tmp dump..."
mariadb-dump $DBNAME --skip-ssl >tmpbkp.sql

echo "Moving old files ..."
sudo mv $MDLHOME $MDLHOME.$DAY.tmpbkp
sudo mv tmpbkp.sql $MDLHOME.$DAY.tmpbkp

mkdir $MDLHOME

echo "moving new files..."
sudo mv /tmp/$MDLCORE/* $MDLHOME
rm -rf /tmp/$MDLCORE

echo "Copying config file ..."
sudo cp $MDLHOME.$DAY.tmpbkp/config.php $MDLHOME

echo "fixing file permissions..."
sudo chmod 740 $MDLHOME/admin/cli/cron.php
sudo chown -R root $MDLHOME
sudo chmod -R 0755 $MDLHOME

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/upgrade.php --non-interactive --allow-unstable
if [[ $? -ne 0 ]]; then # Error in upgrade script
	echo "Error in upgrade script..."
	if [ -d "$MDLHOME.$DAY.tmpbkp" ]; then # If exists
		echo "Database DROP DATABASE ${DBNAME}..."
		mariadb -e "DROP DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
		mariadb -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
		echo "Restore DB.."
		mariadb $DBNAME --skip-ssl <$MDLHOME.$DAY.tmpbkp/tmpbkp.sql
		sudo rm -rf $MDLHOME.$DAY.tmpbkp/tmpbkp.sql
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

MOOSHCMD=$(command -v moosh) # Find moosh
if ! [ -x $MOOSHCMD ]; then
	echo 'Error: moosh is not installed.'
else
	echo $MOOSHCMD
	echo "Update Moodle site name:"
	cd $MDLHOME || exit
	#mdlrelease=$(moosh -n config-get core release) # !!! error/generalexceptionmessage !!!
	mdlrelease=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2)                     # Gets Moodle Version
	sudo /usr/bin/$PHPVER $MOOSHCMD -n course-config-set course 1 fullname "Moodle $mdlrelease"  # !!! error/generalexceptionmessage !!!
	sudo /usr/bin/$PHPVER $MOOSHCMD -n course-config-set course 1 shortname "Moodle $mdlrelease" # !!! error/generalexceptionmessage !!!
fi

echo "Disable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --disable

echo "start cron..."
sudo service cron start

# Verify for Moodle third-party plugins
if [[ ! -v PLGREPO ]] || [[ -z "$PLGREPO" ]]; then
	echo "No third-party installed plugins!"
else
	echo "Prints tab-separated list of all third-party installed plugins..."
	sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/uninstall_plugins.php --show-contrib

	echo "Prints tab-separated list of all missing from disk plugins..."
	sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/uninstall_plugins.php --show-missing
fi
