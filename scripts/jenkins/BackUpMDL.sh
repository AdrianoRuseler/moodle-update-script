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

datastr=$(date) # Generates datastr
echo "" >> $ENVFILE
echo "# ----- $datastr -----" >> $ENVFILE

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
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]]; then
    echo "DBNAME is not set or is set to the empty string!"
    exit 1
else
    echo "DBNAME has the value: $DBNAME"	
fi

BKPDIR="/home/ubuntu/backups/"$LOCALSITENAME  # moodle backup folder
# Verify if folder NOT exists
if [[ ! -d "$BKPDIR" ]]; then
	echo "$BKPDIR NOT exists on your filesystem."
	mkdir $BKPDIR
fi

DBBKP=$BKPDIR"/db/" # moodle database backup folder
# Verify if folder NOT exists
if [[ ! -d "$DBBKP" ]]; then
	echo "$DBBKP NOT exists on your filesystem."
	mkdir $DBBKP
fi

DATABKP=$BKPDIR"/data/"  # moodle data backup folder
# Verify if folder NOT exists
if [[ ! -d "$DATABKP" ]]; then
	echo "$DATABKP NOT exists on your filesystem."
	mkdir $DATABKP
fi

HTMLBKP=$BKPDIR"/html/"  # moodle html backup folder
# Verify if folder NOT exists
if [[ ! -d "$HTMLBKP" ]]; then
	echo "$HTMLBKP NOT exists on your filesystem."
	mkdir $HTMLBKP
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
DATABKPFILE=$DATABKP$BKPNAME.tar.gz
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

# Verify DATABKPFILE if file exists
if [[ -f "$DATABKPFILE" ]]; then
	echo "$DATABKPFILE file exists on your filesystem."
	exit 1
fi

# Verify HTMLBKPFILE if file exists
if [[ -f "$HTMLBKPFILE" ]]; then
	echo "$HTMLBKPFILE file exists on your filesystem."
	exit 1
fi

echo "BKPDIR=\"$BKPDIR\"" >> $ENVFILE
echo "DBBKP=\"$DBBKP\"" >> $ENVFILE
echo "DATABKP=\"$DATABKP\"" >> $ENVFILE
echo "HTMLBKP=\"$HTMLBKP\"" >> $ENVFILE

echo "DBFILE=\"$DBFILE\"" >> $ENVFILE
echo "DBBKPFILE=\"$DBBKPFILE\"" >> $ENVFILE
echo "DATABKPFILE=\"$DATABKPFILE\"" >> $ENVFILE
echo "HTMLBKPFILE=\"$HTMLBKPFILE\"" >> $ENVFILE

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

echo "Activating Moodle Maintenance Mode in..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable


# make database backup
if [[ "$USEDB" == "mariadb" ]]; then
	# echo "USEDB=mariadb"
	mysqldump $DBNAME > $DBFILE
else
	# echo "USEDB=pgsql"
	sudo -i -u postgres pg_dump $DBNAME > $DBFILE
fi

tar -czf $DBBKPFILE $DBFILE
md5sum $DBBKPFILE > $DBBKPFILE.md5
md5sum -c $DBBKPFILE.md5
rm $DBFILE
ls -lh $DBBKP

# Backup the files using tar.
# NB: It is not necessary to copy the contents of these directories: tar -cvf backup.tar --exclude={"public_html/template/cache","public_html/images"} public_html/
# --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"}
tar -czf $DATABKPFILE --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"} $MDLDATA
#tar -czf $DATABKPFILE $MDLDATA
md5sum $DATABKPFILE > $DATABKPFILE.md5
md5sum -c $DATABKPFILE.md5

ls -lh $DATABKP

tar -czf $HTMLBKPFILE $MDLHOME
md5sum $HTMLBKPFILE > $HTMLBKPFILE.md5
md5sum -c $HTMLBKPFILE.md5

ls -lh $HTMLBKP

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable

cd $SCRIPTDIR
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"

