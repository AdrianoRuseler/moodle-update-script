#!/bin/bash

DB_BKP="/mnt/mdl/bkp/db/" # moodle database backup folder
DATA_BKP="/mnt/mdl/bkp/data/" # moodle data backup folder
MOODLE_DATA="/mnt/mdl/data"  # moodle data folder
MOODLE_DB="/mnt/mdl/db/data"  # moodle database folder
MOODLE_HOME="/var/www/moodle/html" # moodle core folder
TMP_DIR="/mnt/mdl/tmp" # Restore temp folder

echo ""
echo "##----------------------- FOLDER CHECK ------------------------##"

echo "Check if Moodle Home folder exists..."
if [ -d "$MOODLE_HOME" ]; then
  ### Take action if $MOODLE_HOME exists ###
  echo "Found Moodle Home folder: ${MOODLE_HOME}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${MOODLE_HOME} not found. Can not continue!"
  echo "Is ${MOODLE_HOME} your Moodle Home directory?"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "Check if Moodle Data folder exists..."
if [ -d "$MOODLE_DATA" ]; then
  ### Take action if $MOODLE_DATA exists ###
  echo "Found Moodle Data folder: ${MOODLE_DATA}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: ${MOODLE_DATA} not found. Can not continue!"
  echo "Is ${MOODLE_DATA} your Moodle Data directory?"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "Activating Moodle Maintenance Mode in..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enable
if [[ $? -ne 0 ]]; then
  echo "Error: Activating Moodle Maintenance Mode!"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "Get latest DB backup files.."
dbmd5file=$(ls -t $DB_BKP | head -2 | grep -e '\bmd5$')
dbgzfile=$(ls -t $DB_BKP | head -2 | grep -e '\bgz$')
echo "Db file to restore: $DB_BKP$dbgzfile"

md5sum -c $DB_BKP$dbmd5file # Check DB file
if [[ $? -ne 0 ]]; then
  echo "Error: Check DB file!"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

echo "Get latest Data backup files.."
datamd5file=$(ls -t $DATA_BKP | head -2 | grep -e '\bmd5$')
datagzfile=$(ls -t $DATA_BKP | head -2 | grep -e '\bgz$')
echo "Data file to restore: $DATA_BKP$datagzfile"

md5sum -c $DATA_BKP$datamd5file # Check data file
if [[ $? -ne 0 ]]; then
  echo "Error: Check data file!"
  echo "##------------------------ FAIL -------------------------##"
  exit 1
fi

filename=$(date +\%Y-\%m-\%d-\%H.\%M) # Generates filename

# make database backup
mdldbname=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbname' | cut -d\' -f 2) # Gets Moodle DB Name
mdldbuser=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbuser' | cut -d\' -f 2) # Gets Moodle DB User
# mdldbpass=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbpass' | cut -d\' -f 2) # Gets Moodle DB Pass

echo "Make database backup..."
sudo -i -u postgres pg_dump $mdldbname | gzip > $DB_BKP$filename.psql.gz
md5sum $DB_BKP$filename.psql.gz > $DB_BKP$filename.psql.gz.md5
md5sum -c $DB_BKP$filename.psql.gz.md5
ls -lh $DB_BKP # list folder content

echo "Drop database..."
sudo -i -u postgres dropdb $mdldbname

echo "Create DB and grant user acess..."
mkdir -p $TMP_DIR # Creates temp dir
touch $TMP_DIR/createdb$mdldbname.sql
echo $'CREATE DATABASE '${mdldbname}$';' >> $TMP_DIR/createdb$mdldbname.sql
echo $'GRANT ALL PRIVILEGES ON DATABASE '${mdldbname}$' TO '${mdldbuser}$';' >> $TMP_DIR/createdb$mdldbname.sql
cat $TMP_DIR/createdb$mdldbname.sql
echo ""

sudo -i -u postgres psql -f $TMP_DIR/createdb$mdldbname.sql
rm $TMP_DIR/createdb$mdldbname.sql

echo "Restore database..."
gunzip -c $DB_BKP$dbgzfile > $TMP_DIR/restoreme.sql
sudo -i -u postgres psql -d $mdldbname -f $TMP_DIR/restoreme.sql
rm $TMP_DIR/restoreme.sql

echo "Remove Moodle DB..."
rm -rf $MOODLE_DATA
mkdir $MOODLE_DATA
tar xvzf $DATA_BKP$datagzfile -C $MOODLE_DATA

chown www-data:www-data -R $MOODLE_DATA

echo "purge Moodle cache..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "fix courses..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix

# echo "Execute some cleanup tasks..."
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\logstore_standard\task\cleanup_task'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\core_files\task\conversion_cleanup_task'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\cache_cleanup_task'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\file_temp_cleanup_task'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\session_cleanup_task'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\tool_recyclebin\task\cleanup_category_bin'
# sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/tool/task/cli/schedule_task.php --execute='\tool_recyclebin\task\cleanup_course_bin'

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

