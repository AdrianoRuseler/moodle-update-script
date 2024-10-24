#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then
	export $(grep -v '^#' .env | xargs)
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
SCRIPTDIR=$(pwd)
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
fi

# Verify for LOCALSITEFOLDER
if [[ ! -v LOCALSITEFOLDER ]] || [[ -z "$LOCALSITEFOLDER" ]]; then
	echo "LOCALSITEFOLDER is not set or is set to the empty string"
	LOCALSITEFOLDER=$LOCALSITENAME
	echo "Now LOCALSITEFOLDER has the value: $LOCALSITEFOLDER"
else
	echo "LOCALSITEFOLDER has the value: $LOCALSITEFOLDER"
fi

datastr=$(date) # Generates datastr
echo "" >>$ENVFILE
echo "# ----- $datastr -----" >>$ENVFILE

MDLDATA="/var/www/data/$LOCALSITEFOLDER"
echo "MDLDATA=\"$MDLDATA\"" >>$ENVFILE
MDLHOME="/var/www/html/$LOCALSITEFOLDER"
echo "MDLHOME=\"$MDLHOME\"" >>$ENVFILE

# Verify if folder exists
if [[ -d "$MDLHOME" ]]; then
	echo "$MDLHOME exists on your filesystem."
else
	echo "$MDLHOME NOT exists on your filesystem."
	exit 1
fi

# Verify if folder exists
if [[ -d "/var/www/data" ]]; then
	echo "/var/www/data exists on your filesystem."
else
	echo "/var/www/data NOT exists on your filesystem."
	mkdir /var/www/data
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
else
	echo "$MDLDATA NOT exists on your filesystem."
	mkdir $MDLDATA
fi

# Empty MDLHOME
if [ -z "$(ls -A $MDLHOME)" ]; then
	echo "$MDLHOME is Empty"
else
	echo "$MDLHOME is Not Empty"
	rm -rf "${MDLHOME:?}/"*
fi

# Empty MDLDATA
if [ -z "$(ls -A $MDLDATA)" ]; then
	echo "$MDLDATA is Empty"
else
	echo "$MDLDATA is Not Empty"
	rm -rf "${MDLDATA:?}/"*
fi

# export MDLBRANCH="MOODLE_311_STABLE"
# export MDLREPO="https://github.com/moodle/moodle.git"
# Verify for Moodle Branch
if [[ ! -v MDLBRANCH ]] || [[ -z "$MDLBRANCH" ]]; then
	echo "MDLBRANCH is not set or is set to the empty string"
	MDLBRANCH='master' # Set to master
	echo "MDLBRANCH=\"$MDLBRANCH\"" >>$ENVFILE
else
	echo "MDLBRANCH has the value: $MDLBRANCH"
fi

# Verify for Moodle Repository
if [[ ! -v MDLREPO ]] || [[ -z "$MDLREPO" ]]; then
	echo "MDLREPO is not set or is set to the empty string"
	MDLREPO='https://github.com/moodle/moodle.git' # Set to master
	echo "MDLREPO=\"$MDLREPO\"" >>$ENVFILE
else
	echo "MDLREPO has the value: $MDLREPO"
fi

# Clone git repository
cd /tmp || exit
git clone --depth=1 --branch=$MDLBRANCH $MDLREPO mdlcore

mv /tmp/mdlcore/* $MDLHOME
rm -rf /tmp/mdlcore

# Fix permissions
chmod 740 $MDLHOME/admin/cli/cron.php
chown www-data:www-data -R $MDLHOME
chown www-data:www-data -R $MDLDATA

cd $SCRIPTDIR || exit
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
