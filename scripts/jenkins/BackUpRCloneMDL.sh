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

# Verifies if 7z is installed
if ! [ -x "$(command -v 7z)" ]; then
    echo 'Error: 7z is not installed.'
    exit 1
else
    echo '7z is installed!'
fi

# Verifies if rclone is installed
if ! [ -x "$(command -v rclone)" ]; then
    echo 'Error: rclone is not installed.'
    exit 1
else
    echo 'rclone is installed!'
    rclone version
fi

# PHP version to use
if [[ ! -v PHPVER ]] || [[ -z "$PHPVER" ]]; then
    echo "PHPVER is not set or is set to the empty string!"
    PHPVER='php' # Uses default version
else
    echo "PHPVER has the value: $PHPVER"
fi

# Verifies if PHPVER is installed
if ! [ -x "$(command -v "$PHPVER")" ]; then
    echo "Error: $PHPVER is not installed."
    exit 1
else
    sudo -u www-data /usr/bin/"$PHPVER" -version # Gets php version
    echo ""
fi

datastr=$(date) # Generates datastr
echo "" >>"$ENVFILE"
echo "# ----- $datastr -----" >>"$ENVFILE"

# Verify for MDLHOME and MDLDATA
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]] || [[ ! -v MDLDATA ]] || [[ -z "$MDLDATA" ]]; then
    echo "MDLHOME or MDLDATA is not set or is set to the empty string!"
    exit 1
else
    echo "MDLHOME has the value: $MDLHOME"
    echo "MDLDATA has the value: $MDLDATA"
fi

# Verify if folder and config.php exists
if [[ -d "$MDLHOME" ]] && [[ -d "$MDLDATA" ]]; then
    echo "$MDLHOME and $MDLDATA exists on your filesystem."
    if [ -f "$MDLHOME/config.php" ]; then
        echo "$MDLHOME/config.php exists!"
    else
        echo "$MDLHOME/config.php does not exist!"
        exit 1
    fi
else
    echo "$MDLHOME or $MDLDATA NOT exists on your filesystem."
    exit 1
fi

# Verify for DESTNAME
if [[ ! -v DESTNAME ]] || [[ -z "$DESTNAME" ]]; then
    echo "DESTNAME is not set or is set to the empty string!"
    exit 1
else
    echo "DESTNAME has the value: $DESTNAME"
    # Verify if remote is configured;
    if [[ "$(rclone listremotes)" == *"$DESTNAME"* ]]; then
        echo "$DESTNAME is configured."
    else
        echo "$DESTNAME Not configured."
        rclone listremotes
        exit 1
    fi
fi

# Verify for DESTPATH
if [[ ! -v DESTPATH ]] || [[ -z "$DESTPATH" ]]; then
    echo "DESTPATH is not set or is set to the empty string!"
    exit 1
else
    echo "DESTPATH has the value: $DESTPATH"
fi

#DBPASS=$(cat $MDLHOME/config.php | grep 'dbpass' | cut -d\' -f 2) # Gets Moodle DB Password

# Verify for DB Credentials
if [[ ! -v DBNAME ]] || [[ -z "$DBNAME" ]]; then
    echo "DBNAME is not set or is set to the empty string!"
    DBNAME=$(cat $MDLHOME/config.php | grep 'dbname' | cut -d\' -f 2) # Gets Moodle DB Name
    echo "DBNAME has been found in config.php: $DBNAME"
else
    echo "DBNAME has the value: $DBNAME"
fi

BKPDIR="/home/ubuntu/backups/"$LOCALSITENAME # moodle backup folder
# Verify if folder NOT exists
if [[ ! -d "$BKPDIR" ]]; then
    echo "$BKPDIR NOT exists on your filesystem."
    mkdir -p $BKPDIR
fi

DBBKP=$BKPDIR"/db/" # moodle database backup folder
# Verify if folder NOT exists
if [[ ! -d "$DBBKP" ]]; then
    echo "$DBBKP NOT exists on your filesystem."
    mkdir -p $DBBKP
fi

DATABKP=$BKPDIR"/data/" # moodle data backup folder
# Verify if folder NOT exists
if [[ ! -d "$DATABKP" ]]; then
    echo "$DATABKP NOT exists on your filesystem."
    mkdir -p $DATABKP
fi

HTMLBKP=$BKPDIR"/html/" # moodle html backup folder
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

# Create backup files names
DBFILE=$DBBKP$BKPNAME.sql
DBBKPFILE=$DBBKP$BKPNAME.7z
DATABKPFILE=$DATABKP$BKPNAME.7z
HTMLBKPFILE=$HTMLBKP$BKPNAME.7z

# Verify if DBFILE or DBBKPFILE or  DATABKPFILE or HTMLBKPFILE file exists
if [[ -f "$DBFILE" ]] || [[ -f "$DBBKPFILE" ]] || [[ -f "$DATABKPFILE" ]] || [[ -f "$HTMLBKPFILE" ]]; then
    echo "Backup file already exists on your filesystem."
    exit 1
fi

# Update .env file
echo "BKPDIR=\"$BKPDIR\"" >>$ENVFILE
echo "DBBKP=\"$DBBKP\"" >>$ENVFILE
echo "DATABKP=\"$DATABKP\"" >>$ENVFILE
echo "HTMLBKP=\"$HTMLBKP\"" >>$ENVFILE

echo "DBFILE=\"$DBFILE\"" >>$ENVFILE
echo "DBBKPFILE=\"$DBBKPFILE\"" >>$ENVFILE
echo "DATABKPFILE=\"$DATABKPFILE\"" >>$ENVFILE
echo "HTMLBKPFILE=\"$HTMLBKPFILE\"" >>$ENVFILE

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/kill_all_sessions.php

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --enable

# make database backup
echo 'Make database backup...'
if [[ "$USEDB" == "mariadb" ]]; then
    # echo "USEDB=mariadb"
    mariadb-dump $DBNAME >$DBFILE
else
    # echo "USEDB=pgsql"
    sudo -i -u postgres pg_dump $DBNAME | sudo tee -a $DBFILE
fi

#tar -czf $DBBKPFILE $DBFILE
echo 'DBBKP 7z...'
7z a $DBBKPFILE $DBFILE
md5sum $DBBKPFILE >$DBBKPFILE.md5
md5sum -c $DBBKPFILE.md5
rm $DBFILE
ls -lh $DBBKP

# rclone copy source:sourcepath destname:destpath DESTNAME:DESTPATH
echo 'DBBKP rclone copy...'
rclone copy --transfers 1 $BKPDIR $DESTNAME:$DESTPATH$LOCALSITENAME

rclone lsd $DESTNAME:$DESTPATH$LOCALSITENAME
rm -rfv $BKPDIR

# Backup the files using tar. TODO
# NB: It is not necessary to copy the contents of these directories: tar -cvf backup.tar --exclude={"public_html/template/cache","public_html/images"} public_html/
# --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"}
#tar -czf $DATABKPFILE --exclude={"$MDLDATA/cache","$MDLDATA/localcache","$MDLDATA/sessions","$MDLDATA/temp","$MDLDATA/trashdir"} $MDLDATA
#tar -czf $DATABKPFILE $MDLDATA
7z a -x'!filedir' $DATABKPFILE $MDLDATA
md5sum $DATABKPFILE >$DATABKPFILE.md5
md5sum -c $DATABKPFILE.md5
ls -lh $DATABKP

FOLDERS=('antivirus_quarantine' 'cache' 'filedir' 'geoip' 'lang' 'localcache' 'models' 'muc' 'sessions' 'temp' 'trashdir')

#ls -lh $DATABKP
#tmpf=/mnt/nvme1n1p1/datadev

#FOLDERS=("$MDLDATA/"*)
for FOLDER in "${FOLDERS[@]}"; do
 #   FOLDER=$(basename "$MDLDATADIR")
    DATABKPFILE=$DATABKP$BKPNAME'/'$FOLDER.7z
    echo $FOLDER' 7z...'
    7z a $DATABKPFILE $MDLDATA'/'$FOLDER
    md5sum $DATABKPFILE >$DATABKPFILE.md5
    md5sum -c $DATABKPFILE.md5
    ls -lh $DATABKP
    echo $FOLDER' rclone copy...'
    rclone copy --transfers 1 $BKPDIR $DESTNAME:$DESTPATH$LOCALSITENAME
    rclone lsd $DESTNAME:$DESTPATH$LOCALSITENAME
    rm -rfv $BKPDIR
done

#tar -czf $HTMLBKPFILE $MDLHOME
echo 'HTMLBKP 7z...'
7z a $HTMLBKPFILE $MDLHOME
md5sum $HTMLBKPFILE >$HTMLBKPFILE.md5
md5sum -c $HTMLBKPFILE.md5

ls -lh $HTMLBKP

# rclone copy source:sourcepath destname:destpath DESTNAME:DESTPATH
echo 'HTMLBKP rclone copy...'
rclone copy --transfers 1 $BKPDIR $DESTNAME:$DESTPATH$LOCALSITENAME

rclone lsd $DESTNAME:$DESTPATH$LOCALSITENAME
rm -rfv $BKPDIR

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/$PHPVER $MDLHOME/admin/cli/maintenance.php --disable

cd $SCRIPTDIR || exit
echo ""
echo "##------------ $ENVFILE -----------------##"
cat $ENVFILE
echo "##------------ $ENVFILE -----------------##"
