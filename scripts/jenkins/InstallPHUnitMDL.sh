#!/bin/bash

# Load Environment Variables
if [ -f .env ]; then
	export "$(grep -v '^#' .env | xargs)"
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
	echo "LOCALSITENAME is not set or is set to the empty string!"
	echo "Choose site to use:"
	ls /etc/apache2/sites-enabled/
	echo "export LOCALSITEFOLDER="
	exit 1
else
	echo "LOCALSITENAME has the value: $LOCALSITENAME"
fi

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then
	echo "/root/.my.cnf exists"
# If /root/.my.cnf doesn't exist then it'll ask for password
else
	if [[ ! -v ADMDBUSER ]] || [[ -z "$ADMDBUSER" ]] || [[ ! -v ADMDBPASS ]] || [[ -z "$ADMDBPASS" ]]; then
		echo "ADMDBUSER or ADMDBPASS is not set or is set to the empty string!"
		exit 1
	fi
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
#	rm $ENVFILE
fi

if [[ ! -v LOCALSITEURL ]] || [[ -z "$LOCALSITEURL" ]]; then
	echo "LOCALSITEURL is not set or is set to the empty string"
	LOCALSITEURL=${LOCALSITENAME}'.local' # Generates ramdon site name
else
	echo "LOCALSITEURL has the value: $LOCALSITEURL"
fi

# Verify for MDLHOME and folder
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
	echo "MDLHOME is not set or is set to the empty string!"
	exit 1
else
	echo "MDLHOME has the value: $MDLHOME"
fi

# Verify for config.php file
if [[ -f "$MDLHOME/config.php" ]]; then
	echo "$MDLHOME/config.php exists."
	MDLCONFIGFILE="$MDLHOME/config.php"
else
	echo "$MDLHOME/config.php NOT exists."
	exit 1
fi

chown www-data:www-data -R $MDLHOME

datastr=$(date) # Generates datastr
echo "" >>$ENVFILE
echo "# ----- $datastr -----" >>$ENVFILE

echo ""
echo "##---------------------- GENERATES PHPUNIT DB -------------------------##"
echo ""

# PHPUNITDBNAME=$(pwgen 10 -s1vA0) # Generates ramdon user name
PHPUNITDBNAME=${LOCALSITENAME}'_phpu'
PHPUNITDBUSER=$PHPUNITDBNAME   # Use same generated ramdon user name
PHPUNITDBPASS=$(pwgen -s 14 1) # Generates ramdon password for db user
# DBPASS="$(openssl rand -base64 12)"
echo "PHPUNIT DB Name: $PHPUNITDBNAME"
echo "PHPUNIT DB User: $PHPUNITDBUSER"
echo "PHPUNIT DB Pass: $PHPUNITDBPASS"
echo ""

# Save Environment Variables
echo "" >>$ENVFILE
echo "# DataBase credentials" >>$ENVFILE
echo "PHPUNITDBNAME=\"$PHPUNITDBNAME\"" >>$ENVFILE
echo "PHPUNITDBUSER=\"$PHPUNITDBUSER\"" >>$ENVFILE
echo "PHPUNITDBPASS=\"$PHPUNITDBPASS\"" >>$ENVFILE

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then
	mysql -e "CREATE DATABASE ${PHPUNITDBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -e "CREATE USER ${PHPUNITDBUSER}@localhost IDENTIFIED BY '${PHPUNITDBPASS}';"
	mysql -e "GRANT ALL PRIVILEGES ON ${PHPUNITDBNAME}.* TO '${PHPUNITDBUSER}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
fi

# Verify for PHPUNITDATA
if [[ ! -v PHPUNITDATA ]] || [[ -z "$PHPUNITDATA" ]]; then
	echo "PHPUNITDATA is not set or is set to the empty string!"
	PHPUNITDATA=/var/www/data/phpunit/${LOCALSITENAME}
	mkdir '/var/www/data/phpunit'
	mkdir $PHPUNITDATA
	echo "PHPUNITDATA=\"$PHPUNITDATA\"" >>$ENVFILE
else
	echo "PHPUNITDATA has the value: $PHPUNITDATA"
fi

chown www-data:www-data -R /var/www/data/phpunit

# Verify for PHPUNITPREFIX
if [[ ! -v PHPUNITPREFIX ]] || [[ -z "$PHPUNITPREFIX" ]]; then
	echo "PHPUNITPREFIX is not set or is set to the empty string!"
	PHPUNITPREFIX=phpu_
	echo "PHPUNITPREFIX=\"$PHPUNITPREFIX\"" >>$ENVFILE
else
	echo "PHPUNITPREFIX has the value: $PHPUNITPREFIX"
fi

sed -i '/require_once*/i $CFG->phpunit_dbtype    = \x27mariadb\x27;' $MDLCONFIGFILE         # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_dblibrary = \x27native\x27;' $MDLCONFIGFILE          # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_dbhost    = \x27localhost\x27;' $MDLCONFIGFILE       # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_dbname = \x27'$PHPUNITDBNAME'\x27;' $MDLCONFIGFILE   # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_dbuser = \x27'$PHPUNITDBUSER'\x27;' $MDLCONFIGFILE   # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_dbpass = \x27'$PHPUNITDBPASS'\x27;\n' $MDLCONFIGFILE # Single quote \x27

sed -i '/require_once*/i $CFG->phpunit_dataroot = \x27'$PHPUNITDATA'\x27;' $MDLCONFIGFILE   # Single quote \x27
sed -i '/require_once*/i $CFG->phpunit_prefix = \x27'$PHPUNITPREFIX'\x27;\n' $MDLCONFIGFILE # Single quote \x27

sudo -u www-data composer -V
#php composer.phar install

# chown www-data:www-data -R /var/www

cd $MDLHOME || exit
sudo -u www-data composer install

echo "Initialise the test environment..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/tool/phpunit/cli/init.php

echo "Let´s run some test:"
vendor/bin/phpunit --testsuite core_favourites_testsuite

cd ~ || exit
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"

#To execute all test suites from main configuration file execute the
# vendor/bin/phpunit

# cat $MDLHOME/phpunit.xml
# vendor/bin/phpunit --testsuite core_phpunit_testsuite

# https://docs.moodle.org/dev/PHPUnit
