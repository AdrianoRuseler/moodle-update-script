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

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
echo "Moodle "$mdlver

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

echo "CLI purge_caches..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/purge_caches.php

echo "CLI kill_all_sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

echo "CLI fix_course_sequence..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_course_sequence.php -c=* --fix

echo "CLI fix_deleted_users..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_deleted_users.php

echo "CLI fix_orphaned_calendar_events..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_orphaned_calendar_events.php

echo "CLI fix_orphaned_question_categories..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/fix_orphaned_question_categories.php

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable
