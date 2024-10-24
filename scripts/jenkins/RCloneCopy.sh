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

# Verifies if rclone is installed
if ! [ -x "$(command -v rclone)" ]; then
	echo 'Error: rclone is not installed.'
	exit 1
else
	echo 'rclone is installed!'
	rclone version
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

# Verify for BKPDIR
if [[ ! -v BKPDIR ]] || [[ -z "$BKPDIR" ]]; then
	echo "BKPDIR is not set or is set to the empty string!"
	exit 1
else
	echo "BKPDIR has the value: $BKPDIR"
fi

# Verify for DESTNAME
if [[ ! -v DESTNAME ]] || [[ -z "$DESTNAME" ]]; then
	echo "DESTNAME is not set or is set to the empty string!"
	DESTNAME='dropbox' #
else
	echo "DESTNAME has the value: $DESTNAME"
fi

# Verify for DESTPATH
if [[ ! -v DESTPATH ]] || [[ -z "$DESTPATH" ]]; then
	echo "DESTPATH is not set or is set to the empty string!"
	DESTPATH='Server-BackUps/MySQL/'
else
	echo "DESTPATH has the value: $DESTPATH"
fi

# BKPDIR="/home/ubuntu/backups/"$LOCALSITENAME  # moodle backup folder
# Verify if folder NOT exists
if [[ ! -d "$BKPDIR" ]]; then
	echo "$BKPDIR NOT exists on your filesystem."
	exit 1
fi

ls -lh $DBBKP

# rclone copy source:sourcepath destname:destpath DESTNAME:DESTPATH
echo 'rclone copy...'
rclone copy --transfers 1 $BKPDIR $DESTNAME:$DESTPATH$LOCALSITENAME

rclone lsd $DESTNAME:$DESTPATH$LOCALSITENAME
