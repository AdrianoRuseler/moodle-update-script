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
echo "# ----------- CourseRestoreMDL --------------" >> $ENVFILE

# Verify for MDLHOME and MDLDATA
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
    echo "MDLHOME is not set or is set to the empty string!"
    exit 1
else
    echo "MDLHOME has the value: $MDLHOME"	
	# Verify if folder exists
	if [[ -d "$MDLHOME" ]]; then
		echo "$MDLHOME exists on your filesystem."
	else
		echo "$MDLHOME NOT exists on your filesystem."
		exit 1
	fi
fi

#Restore backup into provided category.
#Options:
#-f, --file=STRING           Path to the backup file.
#-c, --categoryid=INT        ID of the category to restore too.
#-s, --showdebugging         Show developer level debugging information
#-h, --help                  Print out this help.

#Example:
#\$sudo -u www-data /usr/bin/php admin/cli/restore_backup.php --file=/path/to/backup/file.mbz --categoryid=1\n

# export RESTORECATEGORYID=
# export COURSEBKPFILE=

# Verify for COURSEBKPID and COURSEBKPSHORTNAME
if [[ ! -v RESTORECATEGORYID ]] || [[ -z "$RESTORECATEGORYID" ]] || [[ ! -v COURSEBKPFILE ]] || [[ -z "$COURSEBKPFILE" ]]; then
    echo "RESTORECATEGORYID or COURSEBKPFILE is not set or is set to the empty string!"
	echo "export RESTORECATEGORYID="
	echo "export COURSEBKPFILE="
	exit 1
else
    echo "RESTORECATEGORYID has the value: $RESTORECATEGORYID"
	echo "COURSEBKPFILE has the value: $COURSEBKPFILE"
	# Verify if COURSEBKPFILE NOT exists
	if [[ ! -f "$COURSEBKPFILE" ]]; then
		echo "$COURSEBKPFILE NOT exists on your filesystem."
		exit 1
	fi
fi

echo "COURSEBKPFILE=\"$COURSEBKPFILE\"" >> $ENVFILE
echo "RESTORECATEGORYID=\"$RESTORECATEGORYID\"" >> $ENVFILE

echo "Restore course backup..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/restore_backup.php --showdebugging --file=$COURSEBKPFILE --categoryid=$RESTORECATEGORYID

