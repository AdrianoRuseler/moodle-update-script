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
else
	echo "LOCALSITENAME has the value: $LOCALSITENAME"
fi

ENVFILE='.'${LOCALSITENAME}'.env'
# SCRIPTDIR=$(pwd)
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

echo ""
echo "##------------ SYSTEM INFO -----------------##"
uname -a # Gets system info
echo ""
df -H # Gets disk usage info
echo ""
apache2 -v # Gets apache version
echo ""
php -version # Gets php version
echo ""

echo ""
echo "##------------ GET MAHARA -----------------##"
# https://wiki.mahara.org/wiki/System_Administrator%27s_Guide/Installing_Mahara/How_to_install_Mahara_in_Ubuntu
# https://github.com/MaharaProject/mahara

# https://stackoverflow.com/questions/29109673/is-there-a-way-to-get-the-latest-tag-of-a-given-repo-using-github-api-v3
MAHARAVER=$(curl "https://api.github.com/repos/MaharaProject/mahara/tags" | jq -r '.[0].name')
echo $MAHARAVER

#MAHARAZIPURL=$(curl "https://api.github.com/repos/MaharaProject/mahara/tags" | jq -r '.[0].zipball_url')
#wget $MAHARAZIPURL -O mahara.zip
MAHARATARURL=$(curl "https://api.github.com/repos/MaharaProject/mahara/tags" | jq -r '.[0].tarball_url')
echo $MAHARATARURL

cd /tmp/  || exit
wget $MAHARATARURL -O mahara.tar.gz
rm -rf mahara # if exists
mkdir mahara
tar -xf mahara.tar.gz -C mahara --strip-components=1
rm mahara.tar.gz

echo "##----------------------- MAHARA UPDATE -------------------------##"
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

echo "Moving old files ..."
sudo mv $LOCALSITEDIR $LOCALSITEDIR.$DAY.tmpbkp
mkdir $LOCALSITEDIR

echo "moving new files..."
sudo mv /tmp/mahara/* $LOCALSITEDIR
rm -rf /tmp/mahara

echo "Copying config file ..."
sudo cp $LOCALSITEDIR.$DAY.tmpbkp/htdocs/config.php $LOCALSITEDIR/htdocs

# https://wiki.mahara.org/wiki/System_Administrator%27s_Guide/Upgrading_Mahara#4a._Upgrading_at_the_command-line
sudo chown -R www-data:www-data $LOCALSITEDIR

echo "Upgrading Mahara..."
sudo -u www-data /usr/bin/php $LOCALSITEDIR/htdocs/admin/cli/upgrade.php
if [[ $? -ne 0 ]]; then # Error in upgrade script
	echo "Error in upgrade script..."
	if [ -d "$LOCALSITEDIR.$DAY.tmpbkp" ]; then # If exists
		echo "restoring old files..."
		sudo rm -rf $LOCALSITEDIR                       # Remove new files
		sudo mv $LOCALSITEDIR.$DAY.tmpbkp $LOCALSITEDIR # restore old files
	fi
	echo "##------------------------ FAIL -------------------------##"
	exit 1
fi

echo "Removing temporary backup files..."
cd $LOCALSITEDIR  || exit
cd ..
ls -l
sudo rm -rf $LOCALSITEDIR.$DAY.tmpbkp
