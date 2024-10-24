#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then
	export "$(grep -v '^#' .env | xargs)"
fi

# Verifies if rclone is installed
if ! [ -x "$(command -v rclone)" ]; then
	echo 'Error: rclone is not installed.'
	exit 1
else
	echo 'rclone is installed!'
	rclone version
fi

# Verify for BKPDIR
if [[ ! -v BKPDIR ]] || [[ -z "$BKPDIR" ]]; then
	echo "BKPDIR is not set or is set to the empty string!"
	exit 1
else
	echo "BKPDIR has the value: $BKPDIR"
	# BKPDIR="/home/ubuntu/backups/"$LOCALSITENAME  # Backup folder
	# Verify if folder NOT exists
	if [[ ! -d "$BKPDIR" ]]; then
		echo "$BKPDIR NOT exists on your filesystem."
		exit 1
	fi
fi

# Verify for DESTNAME
if [[ ! -v DESTNAME ]] || [[ -z "$DESTNAME" ]]; then
	echo "DESTNAME is not set or is set to the empty string!"
	exit 1
else
	echo "DESTNAME has the value: $DESTNAME"
	# Verify if remote is configured;
	if [[ "$(rclone listremotes)" == *"$DESTNAME"* ]]; then
		echo "$DESTNAME is configured."
	else
		echo "$DESTNAME Not configured."
		rclone listremotes
		exit 1
	fi
fi

# Verify for DESTPATH
if [[ ! -v DESTPATH ]] || [[ -z "$DESTPATH" ]]; then
	echo "DESTPATH is not set or is set to the empty string!"
	exit 1
else
	echo "DESTPATH has the value: $DESTPATH"
fi

ls -lh $BKPDIR

# rclone copy source:sourcepath destname:destpath DESTNAME:DESTPATH
echo 'rclone copy...'
rclone copy --transfers 1 $BKPDIR $DESTNAME:$DESTPATH

rclone lsd $DESTNAME:$DESTPATH

# rclone md5sum $DESTNAME:$DESTPATH
