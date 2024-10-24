#!/bin/bash

# Load Environment Variables
ENVFILE='.moosh.env'
SCRIPTDIR=$(pwd)
datastr=$(date) # Generates datastr
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
else
	echo "" >>$ENVFILE
	echo "# ----- $datastr -----" >>$ENVFILE
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
	LOCALSITENAME=$(pwgen 10 -s1vA0) # Generates ramdon name
	echo "LOCALSITENAME is set to: $LOCALSITENAME"
	echo "LOCALSITENAME=\"$LOCALSITENAME\"" >>$ENVFILE
else
	echo "LOCALSITENAME has the value: $LOCALSITENAME"
fi

# Verify for LOCALSITEDIR
if [[ ! -v LOCALSITEDIR ]] || [[ -z "$LOCALSITEDIR" ]]; then
	LOCALSITEDIR=$(pwd) # Generates ramdon name
	echo "LOCALSITEDIR is set to: $LOCALSITEDIR"
	echo "LOCALSITEDIR=\"$LOCALSITEDIR\"" >>$ENVFILE
else
	echo "LOCALSITEDIR has the value: $LOCALSITEDIR"
fi

if [[ ! -v LOCALSITEURL ]] || [[ -z "$LOCALSITEURL" ]]; then
	LOCALSITEURL=${LOCALSITENAME}'.local' # Generates ramdon site name
	echo "LOCALSITEURL is set to: $LOCALSITEURL"
	echo "LOCALSITEURL=\"$LOCALSITEURL\"" >>$ENVFILE
else
	echo "LOCALSITEURL has the value: $LOCALSITEURL"
fi

if [[ ! -v MDLDATA ]] || [[ -z "$MDLDATA" ]]; then
	MDLDATA="$LOCALSITEDIR/$LOCALSITENAME/data"
	echo "MDLDATA is set to: $MDLDATA"
	echo "MDLDATA=\"$MDLDATA\"" >>$ENVFILE
else
	echo "MDLDATA has the value: $MDLDATA"
fi

if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
	MDLHOME="$LOCALSITEDIR/$LOCALSITENAME/html"
	echo "MDLHOME is set to: $MDLHOME"
	echo "MDLHOME=\"$MDLHOME\"" >>$ENVFILE
else
	echo "MDLHOME has the value: $MDLHOME"
fi

if [[ ! -v MDLTMP ]] || [[ -z "$MDLTMP" ]]; then
	MDLTMP="$LOCALSITEDIR/$LOCALSITENAME/tmp"
	echo "MDLTMP is set to: $MDLTMP"
	echo "MDLTMP=\"$MDLTMP\"" >>$ENVFILE
else
	echo "MDLTMP has the value: $MDLTMP"
fi

# Verify if folder exists
if [[ -d "$LOCALSITEDIR/$LOCALSITENAME" ]]; then
	echo "$LOCALSITEDIR/$LOCALSITENAME exists on your filesystem."
else
	echo "$LOCALSITEDIR/$LOCALSITENAME NOT exists on your filesystem."
	mkdir "$LOCALSITEDIR/$LOCALSITENAME"
fi

# Verify if folder exists
if [[ -d "$MDLHOME" ]]; then
	echo "$MDLHOME exists on your filesystem."
else
	echo "$MDLHOME NOT exists on your filesystem."
	mkdir $MDLHOME
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
else
	echo "$MDLDATA NOT exists on your filesystem."
	mkdir $MDLDATA
fi

# Verify if folder exists
if [[ -d "$MDLTMP" ]]; then
	echo "$MDLTMP exists on your filesystem."
else
	echo "$MDLTMP NOT exists on your filesystem."
	mkdir $MDLTMP
fi

# Empty MDLHOME
if [ -z "$(ls -A $MDLHOME)" ]; then
	echo "$MDLHOME is Empty"
else
	echo "$MDLHOME is Not Empty"
	rm -rf $MDLHOME/*
fi

# Empty MDLDATA
if [ -z "$(ls -A $MDLDATA)" ]; then
	echo "$MDLDATA is Empty"
else
	echo "$MDLDATA is Not Empty"
	rm -rf $MDLDATA/*
fi

# Empty MDLTMP
if [ -z "$(ls -A $MDLTMP)" ]; then
	echo "$MDLTMP is Empty"
else
	echo "$MDLTMP is Not Empty"
	rm -rf $MDLTMP/*
fi

exit 0 # TODO

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

echo "# -------------- InstallMDL -----------------" >>$ENVFILE

# Verify for DB Credentials
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]] || [[ ! -v DBUSER ]] || [[ -z "$DBUSER" ]] || [[ ! -v DBPASS ]] || [[ -z "$DBPASS" ]]; then
	echo "DB credentials are not set or some are set to the empty string!"
	exit 1
else
	echo "DBNAME has the value: $DBNAME"
	echo "DBUSER has the value: $DBUSER"
	echo "DBPASS has the value: $DBPASS"
fi

# Verify for USEDB; pgsql or mariadb
if [[ ! -v USEDB ]] || [[ -z "$USEDB" ]]; then
	echo "USEDB is not set or is set to the empty string!"
	exit 1
fi

# Fix permissions
chmod 740 $MDLHOME/admin/cli/cron.php
chown www-data:www-data -R $MDLDATA
sudo chown -R root $MDLHOME
sudo chmod -R 0755 $MDLHOME

# The password must have at least 8 characters, at least 1 digit(s), at least 1 lower case letter(s), at least 1 upper case letter(s), at least 1 non-alphanumeric character(s) such as as *, -, or #

# Verify for MDLADMPASS
if [[ ! -v MDLADMPASS ]] || [[ -z "$MDLADMPASS" ]]; then
	echo "MDLADMPASS is not set or is set to the empty string!"
	MDLADMPASS=$(pwgen 12 -s1v)
	echo "MDLADMPASS=\"$MDLADMPASS\"" >>$ENVFILE
else
	echo "MDLADMPASS has the value: $MDLADMPASS"
fi

# cat $MDLHOME/config.php

# Verify for MDLCONFIGDISTFILE
if [[ ! -v MDLCONFIGDISTFILE ]] || [[ -z "$MDLCONFIGDISTFILE" ]]; then
	echo "MDLCONFIGDISTFILE is not set or is set to the empty string!"
	MDLCONFIGDISTFILE="https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/config-dist.php"
	echo "MDLCONFIGDISTFILE=\"$MDLCONFIGDISTFILE\"" >>$ENVFILE
else
	echo "MDLCONFIGDISTFILE has the value: $MDLCONFIGDISTFILE"
fi

MDLCONFIGFILE="$MDLHOME/config.php"
echo "MDLCONFIGFILE=\"$MDLCONFIGFILE\"" >>$ENVFILE

# Copy moodle config file
wget $MDLCONFIGDISTFILE -O $MDLCONFIGFILE

sed -i 's/mydbname/'"$DBNAME"'/' $MDLCONFIGFILE                  # Configure DB Name
sed -i 's/mydbuser/'"$DBUSER"'/' $MDLCONFIGFILE                  # Configure DB user
sed -i 's/mydbpass/'"$DBPASS"'/' $MDLCONFIGFILE                  # Configure DB password
sed -i 's/mysiteurl/https:\/\/'"$LOCALSITEURL"'/' $MDLCONFIGFILE # Configure url
sed -i 's/mydatafolder/'"${MDLDATA##*/}"'/' $MDLCONFIGFILE       # Configure Moodle Data directory

sed -i 's/mydbtype/'"$USEDB"'/' $MDLCONFIGFILE # Configure DB Name

# Verify for MDLCONFIGDISTFILE
if [[ ! -v MDLDEFAULTSDISTFILE ]] || [[ -z "$MDLDEFAULTSDISTFILE" ]]; then
	echo "MDLDEFAULTSDISTFILE is not set or is set to the empty string!"
	MDLDEFAULTSDISTFILE="https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/defaults-dist.php"
	echo "MDLDEFAULTSDISTFILE=\"$MDLDEFAULTSDISTFILE\"" >>$ENVFILE
else
	echo "MDLDEFAULTSDISTFILE has the value: $MDLDEFAULTSDISTFILE"
fi

MDLDEFAULTSFILE="$MDLHOME/local/defaults.php"
echo "MDLDEFAULTSFILE=\"$MDLDEFAULTSFILE\"" >>$ENVFILE

# Copy moodle defaults file
wget $MDLDEFAULTSDISTFILE -O $MDLDEFAULTSFILE
sed -i 's/myadmpass/'"$MDLADMPASS"'/' $MDLDEFAULTSFILE # Set password in file

MDLADMEMAIL='admin@'$LOCALSITEURL
MDLLANG="en"

echo "MDLADMEMAIL=\"$MDLADMEMAIL\"" >>$ENVFILE
echo "MDLLANG=\"$MDLLANG\"" >>$ENVFILE

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/install_database.php --lang=$MDLLANG --adminpass=$MDLADMPASS --agree-license --adminemail=$MDLADMEMAIL --fullname="Moodle $mdlver" --shortname="Moodle $mdlver"

# Config Moodle
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowthemechangeonurl --set=1

# Install H5P content
#sudo -u www-data /usr/bin/php $MDLHOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\h5p_get_content_types_task'

# Add cron for moodle - Shows: no crontab for root
(
	crontab -l | grep .
	echo -e "*/1 * * * * /usr/bin/php  $MDLHOME/admin/cli/cron.php >/dev/null\n"
) | crontab -

# rm $MDLCONFIGFILE
# rm $MDLDEFAULTSFILE

echo ""
echo "##----------- NEW MOODLE SITE URL ----------------##"
echo ""

echo "https://$LOCALSITEURL"

echo ""
echo "##------------------------------------------------##"
echo ""

cd $SCRIPTDIR
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
