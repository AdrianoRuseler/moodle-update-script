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
# SCRIPTDIR=$(pwd)
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

if [[ ! -v FORCEUPDATE ]] || [[ -z "$FORCEUPDATE" ]]; then
	echo "FORCEUPDATE is not set or is set to the empty string!"
	FORCEUPDATE=0 # Dont force update
	echo "Now FORCEUPDATE has the value: $FORCEUPDATE"
else
	echo "FORCEUPDATE has the value: $FORCEUPDATE"
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

echo "Check for free space in $LOCALSITEDIR ..."
REQSPACE=524288 # Required free space: 512 Mb in kB
FREESPACE=$(df "$LOCALSITEDIR" | awk 'NR==2 { print $4 }')
echo "Free space: $FREESPACE"
echo "Req. space: $REQSPACE"
if [[ $FREESPACE -le REQSPACE ]]; then
	echo "NOT enough Space!!"
	echo "##------------------------ FAIL -------------------------##"
	exit 1
else
	echo "Enough Space!!"
fi

echo ""
echo "##------------ VERIFY FOR JQ -----------------##"
if ! [ -x "$(command -v jq)" ]; then
	echo 'Error: jq is not installed.'
	echo 'Use: apt install jq'
	exit 1
fi

echo ""
echo "##------------ GET MEDIAWIKI -----------------##"

# https://stackoverflow.com/questions/29109673/is-there-a-way-to-get-the-latest-tag-of-a-given-repo-using-github-api-v3
# Get latest wiki version
WIKIVER=$(curl "https://api.github.com/repos/wikimedia/mediawiki/tags" | jq -r '.[2].name')
echo $WIKIVER
WIKIV=$(echo $WIKIVER | cut -d. -f1-2)
#echo $WIKIV

# Get actual wiki version
WIKIACTUALVER=$(cat $LOCALSITEDIR/includes/Defines.php | grep "MW_VERSION" | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
echo $WIKIACTUALVER

if [ $WIKIVER == $WIKIACTUALVER ]; then
	echo "Version is up to date"
	if [[ $SYSUPGRADE -ne 0 ]]; then
		echo "Force update!!"
	else
		echo "Dont force update!"
		exit 0
	fi
fi

#WIKITARURL=$(curl "https://api.github.com/repos/wikimedia/mediawiki/tags" | jq -r '.[2].tarball_url')
WIKITARURL="https://releases.wikimedia.org/mediawiki/" $WIKIV "/mediawiki-" $WIKIVER ".tar.gz"
echo $WIKITARURL

cd /tmp/ || exit
wget $WIKITARURL -O mediawiki.tar.gz
if [[ $? -ne 0 ]]; then
	echo "Error: wget ${WIKITARURL}"
	exit 1
fi

rm -rf mediawiki # if exists
mkdir mediawiki
tar -xf mediawiki.tar.gz -C mediawiki --strip-components=1
rm mediawiki.tar.gz

echo "##----------------------- MEDIAWIKI UPDATE -------------------------##"
DAY=$(date +\%Y-\%m-\%d-\%H.\%M)

#echo "##--------------------- Wiki Extensions --------------------------##"
# echo "https://www.mediawiki.org/wiki/Special:ExtensionDistributor"

echo "Moving old files ..."
sudo mv $LOCALSITEDIR $LOCALSITEDIR.$DAY.tmpbkp
mkdir $LOCALSITEDIR

echo "moving new files..."
sudo mv /tmp/mediawiki/* $LOCALSITEDIR

echo "Copying config file ..."
sudo cp $LOCALSITEDIR.$DAY.tmpbkp/LocalSettings.php $LOCALSITEDIR

echo "Copying assets files ..."
sudo cp $LOCALSITEDIR.$DAY.tmpbkp/resources/assets/wikilogo.png $LOCALSITEDIR/resources/assets/
sudo cp $LOCALSITEDIR.$DAY.tmpbkp/resources/assets/favicon.ico $LOCALSITEDIR/resources/assets/

echo "fixing file permissions..."
sudo chown -R www-data:www-data $LOCALSITEDIR

echo "Composer update --no-dev..."
cd $LOCALSITEDIR || exit
sudo -u www-data composer update --no-dev

echo "fixing file permissions..."
sudo chown -R www-data:www-data $LOCALSITEDIR

echo "##------------------ Wiki core update ------------------------##"
echo "Upgrading mediaiwki Core..."
sudo -u www-data /usr/bin/php $LOCALSITEDIR/maintenance/update.php --quick
if [[ $? -ne 0 ]]; then
	echo "Error: Upgrading mediaiwki Core!"
	if [ -d "$LOCALSITEDIR.$DAY.tmpbkp" ]; then # If exists
		echo "restoring old files..."
		sudo rm -rf $LOCALSITEDIR                       # Remove new files
		sudo mv $LOCALSITEDIR.$DAY.tmpbkp $LOCALSITEDIR # restore old files
	fi
	exit 1
fi

echo "Removing temporary backup files..."
sudo rm -rf $LOCALSITEDIR.$DAY.tmpbkp
echo "##---------------------  Success  ---------------------------##"
exit 0
