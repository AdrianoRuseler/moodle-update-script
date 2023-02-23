#!/bin/bash

# Load Environment Variables in .env file
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
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
fi

# Verify for MDLHOME
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
    echo "MDLHOME is not set or is set to the empty string!"
    exit 1
else
    echo "MDLHOME has the value: $MDLHOME"	
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
else
    echo "$MDLDATA NOT exists on your filesystem."
	exit 1
fi

# Verify for USEDB; pgsql or mariadb
if [[ ! -v USEDB ]] || [[ -z "$USEDB" ]]; then
    echo "USEDB is not set or is set to the empty string!"
	USEDB="mariadb"
fi
	
if [[ "$USEDB" == "mariadb" ]]; then
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		echo "/root/.my.cnf exists"
		# If /root/.my.cnf doesn't exist then it'll ask for password   
	else
		if [[ ! -v ADMDBUSER ]] || [[ -z "$ADMDBUSER" ]] || [[ ! -v ADMDBPASS ]] || [[ -z "$ADMDBPASS" ]]; then
			echo "ADMDBUSER or ADMDBPASS is not set or is set to the empty string!"
			exit 1
		fi
	fi
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

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
echo "Moodle "$mdlver

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

echo "CLI kill_all_sessions..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/kill_all_sessions.php

# mysqldump -u [uname] -p db_name table1 table2 > table_backup.sql
# make database backup
if [[ "$USEDB" == "mariadb" ]]; then
	# echo "USEDB=mariadb"
	mysqldump $DBNAME mdl_logstore_standard_log mdl_task_log mdl_upgrade_log > $DBFILE # TODO: verify for table prefix
else
	# echo "USEDB=pgsql"
	sudo -i -u postgres pg_dump $DBNAME mdl_logstore_standard_log mdl_task_log mdl_upgrade_log > $DBFILE # TODO: verify for table prefix
fi

# DELETE FROM mdl_logstore_standard_log;
# DELETE FROM mdl_task_log;

if [[ "$USEDB" == "mariadb" ]]; then
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		mysql -e $'USE '${DBNAME}$'; DELETE FROM mdl_logstore_standard_log;' # TODO: verify for table prefix
		# ALTER TABLE mdl_logstore_standard_log AUTO_INCREMENT = 1
		mysql -e $'USE '${DBNAME}$'; DELETE FROM mdl_task_log;' # TODO: verify for table prefix
		mysql -e $'USE '${DBNAME}$'; DELETE FROM mdl_upgrade_log;' # TODO: verify for table prefix
	# If /root/.my.cnf doesn't exist then it'll ask for password   
	else
		mysql -u${ADMDBUSER} -p${ADMDBPASS} -e $'USE '${DBNAME}$'; DELETE FROM mdl_logstore_standard_log;' # TODO: verify for table prefix
		mysql -u${ADMDBUSER} -p${ADMDBPASS} -e $'USE '${DBNAME}$'; DELETE FROM mdl_task_log;' # TODO: verify for table prefix
		mysql -u${ADMDBUSER} -p${ADMDBPASS} -e $'USE '${DBNAME}$'; DELETE FROM mdl_upgrade_log;' # TODO: verify for table prefix
	fi
else
	touch /tmp/createPGDBUSER.sql
	echo 'DELETE FROM mdl_logstore_standard_log;' >> /tmp/createPGDBUSER.sql
	echo 'DELETE FROM mdl_task_log;' >> /tmp/createPGDBUSER.sql
#	echo $'GRANT ALL PRIVILEGES ON DATABASE '${DBNAME}$' TO '${DBUSER}$';' >> /tmp/createPGDBUSER.sql
	cat /tmp/createPGDBUSER.sql

	sudo -i -u postgres psql -f /tmp/createPGDBUSER.sql # must be sudo
	rm /tmp/createPGDBUSER.sql
fi
	
# NB: It is not necessary to copy the contents of these directories: tar -cvf backup.tar --exclude={"public_html/template/cache","public_html/images"} public_html/
# --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"}	


echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable


