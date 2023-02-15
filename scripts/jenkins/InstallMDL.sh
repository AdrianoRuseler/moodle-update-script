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

if [[ ! -v LOCALSITEURL ]] || [[ -z "$LOCALSITEURL" ]]; then
    echo "LOCALSITEURL is not set or is set to the empty string!"
	LOCALSITEURL=${LOCALSITENAME}'.local' # Generates ramdon site name
else
    echo "LOCALSITEURL has the value: $LOCALSITEURL"
fi

if [[ ! -v PHPVER ]] || [[ -z "$PHPVER" ]]; then
    echo "PHPVER is not set or is set to the empty string!"
	PHPVER='php' # Uses default version
else
    echo "PHPVER has the value: $PHPVER"
fi

# Verifies if pwgen is installed	
if ! [ -x "$(command -v pwgen)" ]; then
	echo 'Error: pwgen is not installed.'
	exit 1
else
	echo 'pwgen is installed!'
fi

datastr=$(date) # Generates datastr
echo "" >> $ENVFILE
echo "# ----- $datastr -----" >> $ENVFILE
echo "# -------------- InstallMDL -----------------" >> $ENVFILE

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
	echo "MDLADMPASS=\"$MDLADMPASS\"" >> $ENVFILE
else
    echo "MDLADMPASS has the value: $MDLADMPASS"	
fi

# cat $MDLHOME/config.php
 
 # Verify for MDLCONFIGDISTFILE
if [[ ! -v MDLCONFIGDISTFILE ]] || [[ -z "$MDLCONFIGDISTFILE" ]]; then
    echo "MDLCONFIGDISTFILE is not set or is set to the empty string!"
	MDLCONFIGDISTFILE="https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/config-dist.php"
	echo "MDLCONFIGDISTFILE=\"$MDLCONFIGDISTFILE\"" >> $ENVFILE
else
    echo "MDLCONFIGDISTFILE has the value: $MDLCONFIGDISTFILE"	
fi
 
MDLCONFIGFILE="$MDLHOME/config.php"
echo "MDLCONFIGFILE=\"$MDLCONFIGFILE\"" >> $ENVFILE
 
# Copy moodle config file
wget $MDLCONFIGDISTFILE -O $MDLCONFIGFILE

sed -i 's/mydbname/'"$DBNAME"'/' $MDLCONFIGFILE # Configure DB Name
sed -i 's/mydbuser/'"$DBUSER"'/' $MDLCONFIGFILE # Configure DB user
sed -i 's/mydbpass/'"$DBPASS"'/' $MDLCONFIGFILE # Configure DB password
sed -i 's/mysiteurl/https:\/\/'"$LOCALSITEURL"'/' $MDLCONFIGFILE # Configure url
sed -i 's/mydatafolder/'"${MDLDATA##*/}"'/' $MDLCONFIGFILE # Configure Moodle Data directory

sed -i 's/mydbtype/'"$USEDB"'/' $MDLCONFIGFILE # Configure DB Name

 # Verify for MDLCONFIGDISTFILE
if [[ ! -v MDLDEFAULTSDISTFILE ]] || [[ -z "$MDLDEFAULTSDISTFILE" ]]; then
    echo "MDLDEFAULTSDISTFILE is not set or is set to the empty string!"
	MDLDEFAULTSDISTFILE="https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/defaults-dist.php"
	echo "MDLDEFAULTSDISTFILE=\"$MDLDEFAULTSDISTFILE\"" >> $ENVFILE
else
    echo "MDLDEFAULTSDISTFILE has the value: $MDLDEFAULTSDISTFILE"	
fi

MDLDEFAULTSFILE="$MDLHOME/local/defaults.php"
echo "MDLDEFAULTSFILE=\"$MDLDEFAULTSFILE\"" >> $ENVFILE

 # Copy moodle defaults file
wget $MDLDEFAULTSDISTFILE -O $MDLDEFAULTSFILE
sed -i 's/myadmpass/'"$MDLADMPASS"'/' $MDLDEFAULTSFILE # Set password in file

MDLADMEMAIL='admin@'$LOCALSITEURL
MDLLANG="en"

echo "MDLADMEMAIL=\"$MDLADMEMAIL\"" >> $ENVFILE
echo "MDLLANG=\"$MDLLANG\"" >> $ENVFILE

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/install_database.php --lang=$MDLLANG --adminpass=$MDLADMPASS --agree-license --adminemail=$MDLADMEMAIL --fullname="Moodle $mdlver" --shortname="Moodle $mdlver"

# Config Moodle
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/cfg.php --name=allowthemechangeonurl --set=1

# Install H5P content
#sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\h5p_get_content_types_task'

# Add cron for moodle - Shows: no crontab for root
(crontab -l | grep . ; echo -e "*/1 * * * * /usr/bin/$PHPVER  $MDLHOME/admin/cli/cron.php >/dev/null\n") | crontab -

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