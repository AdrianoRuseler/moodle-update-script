#!/bin/bash

# systemctl status apache2.service --no-pager --lines=2

# Set web server (apache)
# export LOCALSITENAME="mdl39"
# export LOCALSITEURL="devtest.local"
# export LOCALSITEFOLDER="devtest"
# export LOCALSITEDIR="devtest"

# Load .env
if [ -f .env ]; then
	# Load Environment Variables
	export $(grep -v '^#' .env | xargs)
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
    echo "LOCALSITENAME is not set or is set to the empty string"
	RAMDONNAME=$(pwgen 8 -sv1A0) # Generates ramdon name
	LOCALSITENAME=${RAMDONNAME} # Generates ramdon site name
else
    echo "LOCALSITENAME has the value: $LOCALSITENAME"	
fi

datastr=$(date) # Generates datastr
ENVFILE='.'${LOCALSITENAME}'.env'
echo "" >> $ENVFILE
echo "# ----- $datastr -----" >> $ENVFILE
echo "LOCALSITENAME=\"$LOCALSITENAME\"" >> $ENVFILE

# Verify for LOCALSITEURL
if [[ ! -v LOCALSITEURL ]] || [[ -z "$LOCALSITEURL" ]]; then
    echo "LOCALSITEURL is not set or is set to the empty string"
	LOCALSITEURL=${LOCALSITENAME}'.adrianoruseler.com' # Generates ramdon site name
	echo "LOCALSITEURL=\"$LOCALSITEURL\"" >> $ENVFILE
else
    echo "LOCALSITEURL has the value: $LOCALSITEURL"
fi

# Verify for LOCALSITEFOLDER
if [[ ! -v LOCALSITEFOLDER ]] || [[ -z "$LOCALSITEFOLDER" ]]; then
    echo "LOCALSITEFOLDER is not set or is set to the empty string"
	LOCALSITEFOLDER=${LOCALSITENAME}
	echo "LOCALSITEFOLDER=\"$LOCALSITEFOLDER\"" >> $ENVFILE
else
    echo "LOCALSITEFOLDER has the value: $LOCALSITEFOLDER"
fi

# Verify for LOCALSITEDIR
if [[ ! -v LOCALSITEDIR ]] || [[ -z "$LOCALSITEDIR" ]]; then
    echo "LOCALSITEDIR is not set or is set to the empty string"
	LOCALSITEDIR='/var/www/html/'${LOCALSITENAME} # Site folder location
	echo "LOCALSITEDIR=\"$LOCALSITEDIR\"" >> $ENVFILE
else
    echo "LOCALSITEDIR has the value: $LOCALSITEDIR"
fi

# Verify if folder exists
if [[ -d "$LOCALSITEDIR" ]]; then
	echo "$LOCALSITEDIR exists on your filesystem."
    exit 1
else
    echo "$LOCALSITEFOLDER NOT exists on your filesystem."
fi

# Create new conf files
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf

# Create certificate
openssl req -x509 -out /etc/ssl/certs/${LOCALSITEURL}-selfsigned.crt -keyout /etc/ssl/private/${LOCALSITEURL}-selfsigned.key \
 -newkey rsa:2048 -nodes -sha256 \
 -subj '/CN='${LOCALSITEURL}$'' -extensions EXT -config <( \
  printf "[dn]\nCN='${LOCALSITEURL}$'\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:'${LOCALSITEURL}$'\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
  
# create site folder
mkdir ${LOCALSITEDIR}

# populate site folder with index.php and phpinfo
touch ${LOCALSITEDIR}/index.php
echo '<?php  phpinfo(); ?>' >> ${LOCALSITEDIR}/index.php

# Change site folder and name
sed -i 's/\/var\/www\/html/\/var\/www\/html\/'${LOCALSITEFOLDER}$'/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf
sed -i 's/changetoservername/'${LOCALSITEURL}$'/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf

# Change site log files
sed -i 's/error.log/'${LOCALSITEURL}$'-error.log/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf
sed -i 's/access.log/'${LOCALSITEURL}$'-access.log/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf

# Change site certificate
sed -i 's/ssl-cert-snakeoil.pem/'${LOCALSITEURL}$'-selfsigned.crt/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf
sed -i 's/ssl-cert-snakeoil.key/'${LOCALSITEURL}$'-selfsigned.key/' /etc/apache2/sites-available/${LOCALSITEURL}-ssl.conf

# Enable site
sudo a2ensite ${LOCALSITEURL}-ssl.conf
sudo systemctl reload apache2

echo ""
echo "##------------ SITES ENABLED -----------------##"
echo ""
ls /etc/apache2/sites-enabled/


echo ""
echo "##------------ NEW SITE URL -----------------##"
echo ""
echo "https://$LOCALSITEURL"
echo ""
echo "##------------ NEW SITE URL -----------------##"

echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
echo ""
