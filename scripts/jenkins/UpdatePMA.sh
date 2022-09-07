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

# Verify if folder exists
if [[ -d "$LOCALSITEDIR" ]]; then
	echo "$LOCALSITEDIR exists on your filesystem."
else
    echo "LOCALSITEDIR NOT exists on your filesystem."
	exit 1
fi

cd /tmp/
wget https://raw.githubusercontent.com/phpmyadmin/phpmyadmin/STABLE/README -O PMAREADME
PMAVER=$(sed -n 's/^Version \(.*\)$/\1/p' PMAREADME)

wget 'https://files.phpmyadmin.net/phpMyAdmin/'$PMAVER'/phpMyAdmin-'$PMAVER'-all-languages.tar.xz'
sudo tar -xf phpMyAdmin-$PMAVER-all-languages.tar.xz
sudo rsync -a phpMyAdmin-$PMAVER-all-languages/ $LOCALSITEDIR
sudo chown -R www-data:www-data $LOCALSITEDIR
sudo rm -rf phpMyAdmin-$PMAVER-all-languages phpMyAdmin-$PMAVER-all-languages.tar.xz

cd $LOCALSITEDIR

# https://stackoverflow.com/questions/34539132/updating-phpmyadmin-blowfish-secret-via-bash-shell-script-in-linux
#randomBlowfishSecret=$(openssl rand -base64 32)
randomBlowfishSecret=$(openssl rand -base64 24) # The secret passphrase in configuration (blowfish_secret) is not the correct length. It should be 32 bytes long.

sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" config.sample.inc.php > config.inc.php

sudo systemctl restart mariadb.service

