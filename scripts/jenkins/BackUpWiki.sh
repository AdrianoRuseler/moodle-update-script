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
	echo "export LOCALSITENAME=teste"
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
mariadb --version # Gets mariadb version
echo ""


datastr=$(date) # Generates datastr
echo "" >> $ENVFILE
echo "# ----- $datastr -----" >> $ENVFILE

# Verify for LOCALSITEDIR 
if [[ ! -v LOCALSITEDIR ]] || [[ -z "$LOCALSITEDIR" ]]; then
    echo "LOCALSITEDIR is not set or is set to the empty string!"
    exit 1
else
    echo "LOCALSITEDIR has the value: $LOCALSITEDIR"	
fi


# Verify if folder and LocalSettings.php exists
if [[ -d "$LOCALSITEDIR" ]]; then
	echo "$LOCALSITEDIR exists on your filesystem."
	if [ -f "$LOCALSITEDIR/LocalSettings.php" ]; then
		echo "$LOCALSITEDIR/LocalSettings.php exists!"
	else 
		echo "$LOCALSITEDIR/LocalSettings.php does not exist!"
		exit 1
	fi
else
    echo "$LOCALSITEDIR NOT exists on your filesystem."
	exit 1
fi

#DBPASS=$(cat LocalSettings.php | grep '$wgDBname' | cut -d\" -f 2) # Gets Wiki DB Password
# Verify for DB Credentials
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]]; then
    echo "DBNAME is not set or is set to the empty string!"
	DBNAME=$(cat $LOCALSITEDIR/LocalSettings.php | grep 'wgDBname' | cut -d\" -f 2) # Gets Wiki DB Name
	DBUSER=$(cat $LOCALSITEDIR/LocalSettings.php | grep 'wgDBuser' | cut -d\" -f 2) # Gets Wiki DB User
	DBPASS=$(cat $LOCALSITEDIR/LocalSettings.php | grep 'wgDBpassword' | cut -d\" -f 2) # Gets Wiki DB Pass
    echo "DBNAME has been found in LocalSettings.php: $DBNAME"
else
    echo "DBNAME has the value: $DBNAME"	
fi

BKPDIR="/home/ubuntu/backups/"$LOCALSITENAME  # moodle backup folder
# Verify if folder NOT exists
if [[ ! -d "$BKPDIR" ]]; then
	echo "$BKPDIR NOT exists on your filesystem."
	mkdir -p $BKPDIR
fi

DBBKP=$BKPDIR"/db/" # Wiki database backup folder
# Verify if folder NOT exists
if [[ ! -d "$DBBKP" ]]; then
	echo "$DBBKP NOT exists on your filesystem."
	mkdir -p $DBBKP
fi


HTMLBKP=$BKPDIR"/html/"  # Wiki html backup folder
# Verify if folder NOT exists
if [[ ! -d "$HTMLBKP" ]]; then
	echo "$HTMLBKP NOT exists on your filesystem."
	mkdir -p $HTMLBKP
fi

# Verify for BKPNAME -- Not set on .env file
if [[ ! -v BKPNAME ]] || [[ -z "$BKPNAME" ]]; then
    echo "BKPNAME is not set or is set to the empty string!"
    BKPNAME=$(date +\%Y-\%m-\%d-\%H.\%M)
	echo "Now BKPNAME is set to: $BKPNAME"
else
    echo "BKPNAME has the value: $BKPNAME"	
	# O que fazer caso já exista backup com o nome utilizado?
fi

# Verify for USEDB; pgsql or mariadb
if [[ ! -v USEDB ]] || [[ -z "$USEDB" ]]; then
    echo "USEDB is not set or is set to the empty string!"
	USEDB="mariadb"
fi

DBFILE=$DBBKP$BKPNAME.sql
DBBKPFILE=$DBBKP$BKPNAME.tar.gz
HTMLBKPFILE=$HTMLBKP$BKPNAME.tar.gz

# Verify DBFILE if file exists
if [[ -f "$DBFILE" ]]; then
	echo "$DBFILE file exists on your filesystem."
	exit 1
fi

# Verify DBBKPFILE if file exists
if [[ -f "$DBBKPFILE" ]]; then
	echo "$DBBKPFILE file exists on your filesystem."
	exit 1
fi

# Verify HTMLBKPFILE if file exists
if [[ -f "$HTMLBKPFILE" ]]; then
	echo "$HTMLBKPFILE file exists on your filesystem."
	exit 1
fi

echo "BKPDIR=\"$BKPDIR\"" >> $ENVFILE
echo "DBBKP=\"$DBBKP\"" >> $ENVFILE
echo "HTMLBKP=\"$HTMLBKP\"" >> $ENVFILE

echo "DBFILE=\"$DBFILE\"" >> $ENVFILE
echo "DBBKPFILE=\"$DBBKPFILE\"" >> $ENVFILE
echo "HTMLBKPFILE=\"$HTMLBKPFILE\"" >> $ENVFILE


# PHP version to use
if [[ ! -v PHPVER ]] || [[ -z "$PHPVER" ]]; then
    echo "PHPVER is not set or is set to the empty string!"
	PHPVER='php' # Uses default version
else
    echo "PHPVER has the value: $PHPVER"
fi

# Verifies if PHPVER is installed	
if ! [ -x "$(command -v $PHPVER)" ]; then
	echo "Error: $PHPVER is not installed."
	exit 1
else
	sudo -u www-data /usr/bin/$PHPVER -version # Gets php version
	echo ""
fi

# make database backup
if [[ "$USEDB" == "mariadb" ]]; then
	# echo "USEDB=mariadb"
	mariadb-dump $DBNAME > $DBFILE
else
	# echo "USEDB=pgsql"
	sudo -i -u postgres pg_dump $DBNAME > $DBFILE
fi

tar -czf $DBBKPFILE $DBFILE
md5sum $DBBKPFILE > $DBBKPFILE.md5
md5sum -c $DBBKPFILE.md5
rm $DBFILE
ls -lh $DBBKP


tar -czf $HTMLBKPFILE $LOCALSITEDIR
md5sum $HTMLBKPFILE > $HTMLBKPFILE.md5
md5sum -c $HTMLBKPFILE.md5

ls -lh $HTMLBKP


cd $SCRIPTDIR
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"

