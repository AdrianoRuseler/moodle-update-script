#!/bin/bash

# Load Environment Variables in .env file
if [ -f .env ]; then
	export "$(grep -v '^#' .env | xargs)"
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
	echo "LOCALSITENAME is not set or is set to the empty string"
	echo "Choose site to use:"
	ls /etc/apache2/sites-enabled/
	echo "export LOCALSITENAME="
	exit 1
else
	echo "LOCALSITENAME has the value: $LOCALSITENAME"
fi

ENVFILE='.'${LOCALSITENAME}'.env'
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export "$(grep -v '^#' $ENVFILE | xargs)"
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
fi

# Verify for MDLHOME
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
	echo "MDLHOME is not set or is set to the empty string!"
	exit 1
else
	echo "MDLHOME has the value: $MDLHOME"
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
else
	echo "$MDLDATA NOT exists on your filesystem."
	exit 1
fi

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

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
echo "Moodle "$mdlver

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --enable

echo "CLI kill_all_sessions..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/kill_all_sessions.php

echo "CLI purge_caches..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/purge_caches.php

ls -lh $MDLDATA

echo "Delete Moodle data tmp folders..."
rm -rf $MDLDATA/cache
rm -rf $MDLDATA/localcache
rm -rf $MDLDATA/sessions
rm -rf $MDLDATA/temp
rm -rf $MDLDATA/trashdir

echo "Create Moodle data tmp folders..."
mkdir $MDLDATA/cache
mkdir $MDLDATA/localcache
mkdir $MDLDATA/sessions
mkdir $MDLDATA/temp
mkdir $MDLDATA/trashdir
sudo chown -R www-data:www-data $MDLDATA

ls -lh $MDLDATA

# NB: It is not necessary to copy the contents of these directories: tar -cvf backup.tar --exclude={"public_html/template/cache","public_html/images"} public_html/
# --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"}

echo "CLI fix_course_sequence..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "CLI fix_deleted_users..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_deleted_users.php

echo "CLI fix_orphaned_calendar_events..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_orphaned_calendar_events.php

echo "CLI fix_orphaned_question_categories..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/fix_orphaned_question_categories.php

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --disable
