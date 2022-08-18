#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then	
	export $(grep -v '^#' .env | xargs)
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
    echo "LOCALSITENAME is not set or is set to the empty string!"
	echo "Choose site to use:"
	ls /etc/apache2/sites-enabled/
	echo "export LOCALSITENAME=teste"
else
    echo "LOCALSITENAME has the value: $LOCALSITENAME"	
fi

ENVFILE='.'${LOCALSITENAME}'.env'
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

datastr=$(date) # Generates datastr
echo "" >> $ENVFILE
echo "# ----- $datastr -----" >> $ENVFILE

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

#Options:
#--courseid=INTEGER          Course ID for backup.
#--courseshortname=STRING    Course shortname for backup.
#--destination=STRING        Path where to store backup file. If not set the backup
#                            will be stored within the course backup file area.
#-h, --help                  Print out this help.

#Example:
#\$sudo -u www-data /usr/bin/php admin/cli/backup.php --courseid=2 --destination=/moodle/backup/\n

# export COURSEBKPID=
# export COURSEBKPSHORTNAME=

# Verify for COURSEBKPID and COURSEBKPSHORTNAME
if [[ ! -v COURSEBKPID ]] || [[ -z "$COURSEBKPID" ]]; then
    echo "COURSEBKPID or COURSEBKPID is not set or is set to the empty string!"
	echo "export COURSEBKPID="
	# Verify for COURSEBKPSHORTNAME and COURSEBKPSHORTNAME
	if [[ ! -v COURSEBKPSHORTNAME ]] || [[ -z "$COURSEBKPSHORTNAME" ]]; then
		echo "COURSEBKPSHORTNAME or COURSEBKPSHORTNAME is not set or is set to the empty string!"
		echo "export COURSEBKPSHORTNAME="
		exit 1
	else
		echo "COURSEBKPSHORTNAME has the value: $COURSEBKPSHORTNAME"
		COURSEIDENTIFYER="--courseshortname="$COURSEBKPSHORTNAME
		echo "COURSEBKPSHORTNAME=\"$COURSEBKPSHORTNAME\"" >> $ENVFILE
		echo "COURSEIDENTIFYER=\"$COURSEIDENTIFYER\"" >> $ENVFILE		
	fi
else
    echo "COURSEBKPID has the value: $COURSEBKPID"	
	COURSEIDENTIFYER="--courseid="$COURSEBKPID
	echo "COURSEBKPID=\"$COURSEBKPID\"" >> $ENVFILE
	echo "COURSEIDENTIFYER=\"$COURSEIDENTIFYER\"" >> $ENVFILE
fi

COURSEBKPDIR="/home/ubuntu/backups/"$LOCALSITENAME"/courses/"  # moodle courses backup folder

# Verify if folder NOT exists
if [[ ! -d "$COURSEBKPDIR" ]]; then
	echo "$COURSEBKPDIR NOT exists on your filesystem."
	mkdir $COURSEBKPDIR
fi

echo "COURSEBKPDIR=\"$COURSEBKPDIR\"" >> $ENVFILE
chown www-data:www-data -R $COURSEBKPDIR

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

echo "Activating Moodle Maintenance Mode in..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

echo "Course backup..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/backup.php $COURSEIDENTIFYER --destination=$COURSEBKPDIR

echo "Disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable

# https://stackoverflow.com/questions/4561895/how-to-recursively-find-the-latest-modified-file-in-a-directory
COURSEBKPFILE=$(find $COURSEBKPDIR -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
echo "COURSEBKPFILE=\"$COURSEBKPFILE\"" >> $ENVFILE

ls -l $COURSEBKPDIR