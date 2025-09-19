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

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl first."
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install Git first."
    exit 1
fi

# Check if composer is installed
if ! command -v composer &> /dev/null; then
    echo "Error: composer is not installed. Please install composer first."
    exit 1
else
    echo "Composer version: $(composer --version)"

fi


echo ""
echo "##------------ GET MEDIAWIKI -----------------##"

# URL of the MediaWiki core repository
REPO_URL="https://gerrit.wikimedia.org/r/mediawiki/core"

echo "Fetching branch names from $REPO_URL..."

# Get branches, filter for REL1_, sort numerically, and get the highest up to REL1_43
HIGHEST_BRANCH=$(git ls-remote --heads "$REPO_URL" |
    awk '{print $2}' |
    sed 's#refs/heads/##' |
    grep '^REL1_[0-9]\+$' |
    sort -t_ -k2 -n |
    tail -n 1)

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch branch names"
    exit 1
fi

if [ -z "$HIGHEST_BRANCH" ]; then
    echo "No REL1_XX branches"
else
    echo "Highest release branch: $HIGHEST_BRANCH"
    # Convert REL1_43 to 1.43
    VERSION=$(echo "$HIGHEST_BRANCH" | sed 's/REL1_/1./')
    echo "Highest release version: $VERSION"
fi

# URL for the release directory
RELEASE_URL="https://releases.wikimedia.org/mediawiki/$VERSION"

echo "Looking for .tar.gz files in $RELEASE_URL..."

# Fetch and filter .tar.gz files
TAR_FILES=$(curl -s "$RELEASE_URL/" |
    grep -o 'href="[^"]*\.tar\.gz"' |
    sed 's/href="//' |
    sed 's/"//')

if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch files from $RELEASE_URL"
    exit 1
fi



if [ -z "$TAR_FILES" ]; then
    echo "No .tar.gz files found in $RELEASE_URL"
    exit 1
else
    # Sort by version number to find the highest subversion
    HIGHEST_TAR=$(echo "$TAR_FILES" |
        grep "^mediawiki-$VERSION\." |
        sort -t. -k3 -n |
        tail -n 1)

    if [ -z "$HIGHEST_TAR" ]; then
        # Fallback to base version if no subversions exist
        HIGHEST_TAR=$(echo "$TAR_FILES" |
            grep "^mediawiki-$VERSION\.tar\.gz$" |
            head -n 1)
    fi

    if [ -z "$HIGHEST_TAR" ]; then
        echo "No matching mediawiki-$VERSION*.tar.gz files found"
        exit 1
    else
        # Generate full download URL
        DOWNLOAD_URL="$RELEASE_URL/$HIGHEST_TAR"
        echo "Highest subversion .tar.gz file: $HIGHEST_TAR"
        echo "Download URL: $DOWNLOAD_URL"
    fi
fi

# Check if the latest version is already installed
# Get actual wiki version (adjust path to Defines.php as needed)
#LOCALSITEDIR="/path/to/your/mediawiki"
WIKIACTUALVER=$(grep "MW_VERSION" "$LOCALSITEDIR/includes/Defines.php" | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')
echo "$WIKIACTUALVER"

# Compare versions
if [ "$VERSION" = "$WIKIACTUALVER" ]; then
    echo "Version is up to date"
    if [[ ${SYSUPGRADE:-0} -ne 0 ]]; then
        echo "Force update!!"
    else
        echo "Dont force update!"
        exit 0
    fi
fi

cd /tmp/ || exit 1
wget "$DOWNLOAD_URL" -O mediawiki.tar.gz
if [[ $? -ne 0 ]]; then
    echo "Error: wget ${DOWNLOAD_URL}"
    exit 1
fi

echo "Download complete!"

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
#sudo -u www-data /usr/bin/php $LOCALSITEDIR/maintenance/update.php --quick
sudo -u www-data /usr/bin/php $LOCALSITEDIR/maintenance/run.php update --quick
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
