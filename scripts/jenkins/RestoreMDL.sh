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
	echo "export LOCALSITENAME="
else
    echo "LOCALSITENAME has the value: $LOCALSITENAME"	
fi

ENVFILE='.'${LOCALSITENAME}'.env'
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

# Verify for BKPNAME -- Not set on .env file
if [[ ! -v BKPNAME ]] || [[ -z "$BKPNAME" ]]; then
    echo "BKPNAME is not set or is set to the empty string!"
	echo "Restore lasta backup in .env file"
else
    echo "BKPNAME has the value: $BKPNAME"	
	DBFILE=$DBBKP$BKPNAME.sql
	DBBKPFILE=$DBBKP$BKPNAME.tar.gz
	DATABKPFILE=$DATABKP$BKPNAME.tar.gz
	HTMLBKPFILE=$HTMLBKP$BKPNAME.tar.gz
fi

# Verify for DBBKPFILE,  DATABKPFILE and HTMLBKPFILE
if [[ ! -v DBBKPFILE ]] || [[ -z "$DBBKPFILE" ]] || [[ ! -v DATABKPFILE ]] || [[ -z "$DATABKPFILE" ]] || [[ ! -v HTMLBKPFILE ]] || [[ -z "$HTMLBKPFILE" ]]; then
    echo "DBBKPFILE or DATABKPFILE or HTMLBKPFILE is not set or is set to the empty string!"
    exit 1
else
	echo "DBBKPFILE has the value: $DBBKPFILE"
	echo "DATABKPFILE has the value: $DATABKPFILE"	
    echo "HTMLBKPFILE has the value: $HTMLBKPFILE"	
fi

# Verify if files exists
if [[ -f "$DBBKPFILE" ]] && [[ -f "$DATABKPFILE" ]] && [[ -f "$HTMLBKPFILE" ]]; then
	echo "DBBKPFILE and DATABKPFILE and HTMLBKPFILE exists on your filesystem."
else
    echo "DBBKPFILE or DATABKPFILE or HTMLBKPFILE NOT exists on your filesystem."
	exit 1
fi

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

TMPFOLDER=/tmp/$LOCALSITENAME
if [[ -d "$TMPFOLDER" ]]; then
	rm -rf $TMPFOLDER
fi

mkdir $TMPFOLDER

# Verify file integrity 
md5sum -c $DATABKPFILE.md5
if [[ $? -ne 0 ]]; then
    echo "Error: md5sum -c $DATABKPFILE.md5"
    exit 1
else
	tar xzf $DATABKPFILE -C $TMPFOLDER
fi

ls -l $TMPFOLDER$MDLDATA

md5sum -c $HTMLBKPFILE.md5
if [[ $? -ne 0 ]]; then
    echo "Error: md5sum -c $HTMLBKPFILE.md5"
    exit 1
else
	tar xzf $HTMLBKPFILE -C $TMPFOLDER 
fi
ls -l $TMPFOLDER$MDLHOME

md5sum -c $DBBKPFILE.md5
if [[ $? -ne 0 ]]; then
    echo "Error: md5sum -c $DBBKPFILE.md5"
    exit 1
else
	tar xzf $DBBKPFILE -C $TMPFOLDER
	FILEDIR=$(dirname "$DBBKPFILE")
fi
ls -l $TMPFOLDER$FILEDIR

if [[ ! -f "$TMPFOLDER$DBFILE" ]]; then
    echo "File NOT found: $TMPFOLDER$DBFILE"
    exit 1
fi

# Verify for USEDB; pgsql or mariadb
if [[ ! -v USEDB ]] || [[ -z "$USEDB" ]]; then
    echo "USEDB is not set or is set to the empty string!"
	USEDB="mariadb"
fi

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

echo "Activating Moodle Maintenance Mode in..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

if [[ "$USEDB" == "mariadb" ]]; then
	echo "Database tmp dump..." 
	mariadb-dump $DBNAME > $TMPFOLDER.tmp.sql
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		echo "Database DROP DATABASE ${DBNAME}..." 
		mariadb -e "DROP DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
		mariadb -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
		echo "Restore DB.." 
		mariadb ${DBNAME} < $TMPFOLDER$DBFILE
	# If /root/.my.cnf doesn't exist then it'll ask for password   
	else
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "DROP DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	fi	
else
	echo "USEDB=pgsql"
	sudo -i -u postgres pg_dump $DBNAME > $TMPFOLDER.tmp.sql
	touch /tmp/ClearPGDBUSER.sql
	echo $'DROP DATABASE '${DBNAME}$';' >> /tmp/ClearPGDBUSER.sql
	echo $'CREATE DATABASE '${DBNAME}$';' >> /tmp/ClearPGDBUSER.sql
	cat /tmp/ClearPGDBUSER.sql
	sudo -i -u postgres psql -f /tmp/ClearPGDBUSER.sql > /dev/null # must be sudo
	rm /tmp/ClearPGDBUSER.sql
	sudo -i -u postgres psql -d $DBNAME -f $TMPFOLDER$DBFILE > /dev/null 
fi

echo "Moving old files ..."
sudo mv $MDLHOME $MDLHOME.tmpbkp
mkdir $MDLHOME
sudo mv $MDLDATA $MDLDATA.tmpbkp
mkdir $MDLDATA

echo "moving new files..."
sudo mv $TMPFOLDER$MDLHOME/* $MDLHOME
sudo mv $TMPFOLDER$MDLDATA/* $MDLDATA

# Fix permissions
chmod 740 $MDLHOME/admin/cli/cron.php
chown www-data:www-data -R $MDLDATA
sudo chown -R root $MDLHOME
sudo chmod -R 0755 $MDLHOME

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable

echo "Remove tmp folders..."
rm -rf $MDLHOME.tmpbkp $MDLDATA.tmpbkp $TMPFOLDER