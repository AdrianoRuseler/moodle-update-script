#!/bin/bash

# Set web server (apache)
# export ADMDBUSER="dbadmuser"
# export ADMDBPASS="dbadmpass"

# nano /root/.my.cnf
# [client]
# user="dbadmuser"
# password="dbadmpass"

# Load .env
if [ -f .env ]; then
	# Load Environment Variables
	export $(grep -v '^#' .env | xargs)
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
	echo "LOCALSITENAME is not set or is set to the empty string!"
	DBNAME=$(pwgen 10 -s1vA0) # Generates ramdon db name
else
	DBNAME=$LOCALSITENAME
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

# Verifies if pwgen is installed
if ! [ -x "$(command -v pwgen)" ]; then
	echo 'Error: pwgen is not installed.'
	exit 1
else
	echo 'pwgen is installed!'
fi

datastr=$(date) # Generates datastr
ENVFILE='.'${DBNAME}'.env'
echo "" >>$ENVFILE
echo "# ----- $datastr -----" >>$ENVFILE
echo "USEDB=\"$USEDB\"" >>$ENVFILE

echo ""
echo "##---------------------- GENERATES NEW DB -------------------------##"
echo ""

#DBUSER=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon user name
DBUSER=$DBNAME          # Use same generated ramdon user name
DBPASS=$(pwgen -s 14 1) # Generates ramdon password for db user
# DBPASS="$(openssl rand -base64 12)"
echo "DB Name: $DBNAME"
echo "DB User: $DBUSER"
echo "DB Pass: $DBPASS"
echo ""

# Save Environment Variables
echo "" >>$ENVFILE
echo "# DataBase credentials" >>$ENVFILE
echo "DBNAME=\"$DBNAME\"" >>$ENVFILE
echo "DBUSER=\"$DBUSER\"" >>$ENVFILE
echo "DBPASS=\"$DBPASS\"" >>$ENVFILE

if [[ "$USEDB" == "mariadb" ]]; then
	# If /root/.my.cnf exists then it won't ask for root password
	if [ -f /root/.my.cnf ]; then
		mariadb -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;" --skip-ssl
		mariadb -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${DBPASS}';" --skip-ssl
		mariadb -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';" --skip-ssl
		mariadb -e "FLUSH PRIVILEGES;" --skip-ssl
	# If /root/.my.cnf doesn't exist then it'll ask for password
	else
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "CREATE DATABASE ${DBNAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${DBPASS}';"
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "GRANT ALL PRIVILEGES ON ${DBNAME}.* TO '${DBUSER}'@'localhost';"
		mariadb -u${ADMDBUSER} -p${ADMDBPASS} -e "FLUSH PRIVILEGES;"
	fi
else
	touch /tmp/createPGDBUSER.sql
	echo $'CREATE DATABASE '${DBNAME}$';' >>/tmp/createPGDBUSER.sql
	echo $'CREATE USER '${DBUSER}$' WITH PASSWORD \''${DBPASS}$'\';' >>/tmp/createPGDBUSER.sql
	echo $'GRANT ALL PRIVILEGES ON DATABASE '${DBNAME}$' TO '${DBUSER}$';' >>/tmp/createPGDBUSER.sql
	cat /tmp/createPGDBUSER.sql

	sudo -i -u postgres psql -f /tmp/createPGDBUSER.sql # must be sudo
	rm /tmp/createPGDBUSER.sql
fi

echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
echo ""
