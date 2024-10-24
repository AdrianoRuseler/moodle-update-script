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

# Verify for MDLHOME and MDLDATA
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]] || [[ ! -v MDLDATA ]] || [[ -z "$MDLDATA" ]]; then
	echo "MDLHOME or MDLDATA is not set or is set to the empty string!"
	exit 1
else
	echo "MDLHOME has the value: $MDLHOME"
	echo "MDLDATA has the value: $MDLDATA"
fi

# Verify if folder exists
if [[ -d "$MDLHOME" ]]; then
	echo "$MDLHOME exists on your filesystem."
else
	echo "$MDLHOME NOT exists on your filesystem."
	exit 1
fi

# Verify if folder exists
if [[ -d "$MDLDATA" ]]; then
	echo "$MDLDATA exists on your filesystem."
	rm -rf $MDLDATA
	mkdir $MDLDATA
else
	echo "$MDLDATA NOT exists on your filesystem."
	exit 1
fi

# Verify for DB Credentials
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]] || [[ ! -v DBUSER ]] || [[ -z "$DBUSER" ]] || [[ ! -v DBPASS ]] || [[ -z "$DBPASS" ]]; then
	echo "DB credentials are not set or some are set to the empty string!"
	exit 1
else
	echo "DBNAME has the value: $DBNAME"
	echo "DBUSER has the value: $DBUSER"
	echo "DBPASS has the value: $DBPASS"
fi

# Verify for config.php file
if [[ -f "$MDLHOME/config.php" ]]; then
	echo "$MDLHOME/config.php exists and will be removed."
	rm $MDLHOME/config.php
else
	echo "$MDLHOME/config.php NOT exists."
fi

# Verify for local/defaults.php file
if [[ -f "$MDLHOME/local/defaults.php" ]]; then
	echo "$MDLHOME/local/defaults.php exists and will be removed."
	rm $MDLHOME/local/defaults.php
else
	echo "$MDLHOME/local/defaults.php NOT exists."
fi

# Verify for USEDB; pgsql or mariadb
if [[ ! -v USEDB ]] || [[ -z "$USEDB" ]]; then
	echo "USEDB is not set or is set to the empty string!"
	USEDB="mariadb"
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

if [[ "$USEDB" == "mariadb" ]]; then
	echo "USEDB=mariadb"
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		mariadb -e "DROP DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
		mariadb -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
	# If /root/.my.cnf doesn't exist then it'll ask for password
	else
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "DROP DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
	fi
else
	echo "USEDB=pgsql"
	touch /tmp/ClearPGDBUSER.sql
	echo $'DROP DATABASE '${DBNAME}$';' >>/tmp/ClearPGDBUSER.sql
	echo $'CREATE DATABASE '${DBNAME}$';' >>/tmp/ClearPGDBUSER.sql
	cat /tmp/ClearPGDBUSER.sql
	sudo -i -u postgres psql -f /tmp/ClearPGDBUSER.sql # must be sudo
	rm /tmp/ClearPGDBUSER.sql
fi
