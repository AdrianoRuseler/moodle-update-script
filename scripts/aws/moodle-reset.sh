#!/bin/bash

DB_BKP="/mnt/mdl/bkp/db/" # moodle database backup folder
DATA_BKP="/mnt/mdl/bkp/data/" # moodle data backup folder
HTML_BKP="/mnt/mdl/bkp/html/" # moodle html backup folder
MOODLE_DATA="/mnt/mdl/data"  # moodle data folder
MOODLE_DB="/mnt/mdl/db/data"  # moodle database folder
MOODLE_HOME="/var/www/moodle/html" # moodle core folder
TMP_DIR="/mnt/mdl/tmp" # Temp folder

filename=$(date +\%Y-\%m-\%d-\%H.\%M) # Generates filename

# make database backup
mdldbname=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbname' | cut -d\' -f 2) # Gets Moodle DB Name
mdldbuser=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbuser' | cut -d\' -f 2) # Gets Moodle DB User
# mdldbpass=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbpass' | cut -d\' -f 2) # Gets Moodle DB Pass

echo "Make database backup..."
sudo -i -u postgres pg_dump $mdldbname | gzip > $DB_BKP$filename.psql.gz
md5sum $DB_BKP$filename.psql.gz > $DB_BKP$filename.psql.gz.md5
md5sum -c $DB_BKP$filename.psql.gz.md5
ls -lh $DB_BKP # list folder content

echo "Drop database..."
sudo -i -u postgres dropdb $mdldbname

echo "Create DB and grant user acess..."
mkdir -p $TMP_DIR # Creates temp dir
touch $TMP_DIR/createdb$mdldbname.sql
echo $'CREATE DATABASE '${mdldbname}$';' >> $TMP_DIR/createdb$mdldbname.sql
echo $'GRANT ALL PRIVILEGES ON DATABASE '${mdldbname}$' TO '${mdldbuser}$';' >> $TMP_DIR/createdb$mdldbname.sql
cat $TMP_DIR/createdb$mdldbname.sql
echo ""

sudo -i -u postgres psql -f $TMP_DIR/createdb$mdldbname.sql
rm $TMP_DIR/createdb$mdldbname.sql


# MOODLE_DATA="/mnt/mdl/data"  # moodle data folder

# Backup the files using tar.
echo "Make Moodle Data backup..."
tar -C $MOODLE_DATA -czf $DATA_BKP$filename.tar.gz cache filedir lang localcache muc temp trashdir
md5sum $DATA_BKP$filename.tar.gz > $DATA_BKP$filename.tar.gz.md5
md5sum -c $DATA_BKP$filename.tar.gz.md5

ls -lh -t $DATA_BKP # list folder content

echo "Remove Moodle DB..."
rm -rf $MOODLE_DATA
mkdir $MOODLE_DATA
chown www-data:www-data -R $MOODLE_DATA


mdlver=$(cat $MOODLE_HOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
MDLADMPASS=$(pwgen -s 14 1) # Generates new ramdon password for Moodle Admin

echo "Remove defaults..."
rm $MOODLE_HOME/local/defaults.php

echo "Set new defaults for Moodle..."
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/defaults-dist.php -O $MOODLE_HOME/local/defaults.php

# Gets public hostname
PUBHOST=$(ec2metadata --public-hostname | cut -d : -f 2 | tr -d " ")
sed -i 's/mytesturl/'"$PUBHOST"'/' $MOODLE_HOME/local/defaults.php

MDLADMPASS=$(pwgen -s 14 1) # Generates ramdon password for Moodle Admin
sed -i 's/myadmpass/'"$MDLADMPASS"'/' $MOODLE_HOME/local/defaults.php # Set password in file

# Set email sender
if [[ -z "${SMTP_HOST}" ]]; then # If variable is defined
	echo "Email sender not defined!!"
else
# Email Setup
	echo '' >> /var/www/moodle/html/local/defaults.php
	echo $'$defaults[\'moodle\'][\'smtphosts\'] = \''${SMTP_HOST}$':587\';' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'smtpsecure\'] = \'tls\';' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'smtpauthtype\'] = \'LOGIN\';' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'smtpuser\'] = \''${SMTP_USER}$'\';' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'smtppass\'] = \''${SMTP_PASS}$'\';' >> $MOODLE_HOME/local/defaults.php
	echo '' >> $MOODLE_HOME/local/defaults.php
fi

# Set BigBluButton server
if [[ -z "${BBB_URL}" ]]; then # If variable is defined
	echo "BBB server not defined!!"
else
# Email Setup
	echo '' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'bigbluebuttonbn_server_url\'] = \''${BBB_URL}$'\';' >> $MOODLE_HOME/local/defaults.php
	echo $'$defaults[\'moodle\'][\'bigbluebuttonbn_shared_secret\'] = \''${BBB_SECRET}$'\';' >> $MOODLE_HOME/local/defaults.php
	echo '' >> $MOODLE_HOME/local/defaults.php
fi

#Install moodle database
if [[ -z "${ADM_EMAIL}" ]]; then # If variable is defined
  sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/install_database.php --lang=pt_br --adminpass=$MDLADMPASS --agree-license --adminemail=admin@fake.mail --fullname="Moodle $mdlver" --shortname="Moodle $mdlver"
else
  sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/install_database.php --lang=pt_br --adminpass=$MDLADMPASS --agree-license --adminemail=$ADM_EMAIL --fullname="Moodle $mdlver" --shortname="Moodle $mdlver"
fi


