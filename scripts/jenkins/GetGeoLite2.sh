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
    echo "LOCALSITENAME is not set or is set to the empty string"
    exit 1
else
    echo "LOCALSITEFOLDER has the value: $LOCALSITEFOLDER"	
fi

# export YOUR_LICENSE_KEY="secretkeyhere"
if [[ ! -v YOUR_LICENSE_KEY ]] || [[ -z "$YOUR_LICENSE_KEY" ]]; then
    echo "YOUR_LICENSE_KEY is not set or is set to the empty string"
    exit 1
else
    echo "YOUR_LICENSE_KEY has the value: $YOUR_LICENSE_KEY"	
fi

# Verify for MDLDATA
if [[ ! -v MDLDATA ]] || [[ -z "$MDLDATA" ]]; then
    echo "MDLDATA is not set or is set to the empty string!"
    exit 1
else
    echo "MDLDATA has the value: $MDLDATA"	
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
else
    echo "$MDLDATA NOT exists on your filesystem."
	mkdir $MDLDATA
fi

# Verify for GEOIPDIR
if [[ ! -v GEOIPDIR ]] || [[ -z "$GEOIPDIR" ]]; then
    echo "GEOIPDIR is not set or is set to the empty string"
    GEOIPDIR="$MDLDATA/geoip/"
	echo "Now is set to: $GEOIPDIR"
	datastr=$(date) # Generates datastr
	echo "# ----- $datastr -----" >> $ENVFILE
	echo "GEOIPDIR=\"$GEOIPDIR\"" >> $ENVFILE
else
    echo "GEOIPDIR has the value: $GEOIPDIR"	
fi

# Verify if folder exists
if [[ -d "$GEOIPDIR" ]]; then
	echo "$GEOIPDIR exists on your filesystem."
else
    echo "$GEOIPDIR NOT exists on your filesystem."
	mkdir $GEOIPDIR
fi



# Clone git repository
cd /tmp
wget "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$YOUR_LICENSE_KEY&suffix=tar.gz" -O GeoIP2-City.tar.gz
tar -xvzf GeoIP2-City.tar.gz --strip-components 1 -C $GEOIPDIR

rm -rf /tmp/GeoIP2-City.tar.gz

# Fix permissions
chown www-data:www-data -R $MDLDATA

cd $SCRIPTDIR
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
