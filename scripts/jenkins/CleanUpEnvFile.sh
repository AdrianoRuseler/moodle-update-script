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
NEWENVFILE='.'${LOCALSITENAME}'tmp.env'

datastr=$(date) # Generates datastr

echo "" >> $NEWENVFILE
echo "# ----- $datastr -----" >> $NEWENVFILE
echo "# ------------ CleanUpEnvFile ---------------" >> $ENVFILE

# Remove comments | Reverse line order | Remove duplicate | Reverse line order | Print to file
grep -v '^#' $ENVFILE | sed -n '1!G;h;$p' | awk -F "=" '!a[$1]++' | sed -n '1!G;h;$p' >> $NEWENVFILE

echo "" >> $NEWENVFILE
echo "# ------------ CleanUpEnvFile ---------------" >> $ENVFILE


export $(grep -v '^#' $NEWENVFILE | xargs)

# Verify if files exists
if [[ -f "$DBBKPFILE" ]] && [[ -f "$DATABKPFILE" ]] && [[ -f "$HTMLBKPFILE" ]]; then
	echo "DBBKPFILE and DATABKPFILE and HTMLBKPFILE exists on your filesystem."
else
    echo "DBBKPFILE or DATABKPFILE or HTMLBKPFILE NOT exists on your filesystem."
	sed -i /"DBFILE=*"/d $NEWENVFILE
	sed -i /"DBBKPFILE=*"/d $NEWENVFILE
	sed -i /"DATABKPFILE=*"/d $NEWENVFILE
	sed -i /"HTMLBKPFILE=*"/d $NEWENVFILE
fi

mv $NEWENVFILE $ENVFILE

echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
echo ""



