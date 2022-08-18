#!/bin/bash

DB_BKP="/mnt/mdl/bkp/db/" # moodle database backup folder
DATA_BKP="/mnt/mdl/bkp/data/" # moodle data backup folder
HTML_BKP="/mnt/mdl/bkp/html/" # moodle html backup folder
MOODLE_DATA="/mnt/mdl/data"  # moodle data folder
MOODLE_DB="/mnt/mdl/db/data"  # moodle database folder
MOODLE_HOME="/var/www/moodle/html" # moodle core folder

echo "Run automated backup..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/automated_backups.php

echo "Kill all user sessions..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

echo "Activating Moodle Maintenance Mode in..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enable

echo "Purge Moodle cache..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "Fix courses..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/fix_course_sequence.php -c=* --fix


filename=$(date +\%Y-\%m-\%d-\%H.\%M) # Generates filename

# make database backup
mdldbname=$(cat $MOODLE_HOME/config.php | grep '$CFG->dbname' | cut -d\' -f 2) # Gets Moodle DB Name

# sudo -i -u postgres pg_dump $mdldbname > $DB_BKP$filename.$mdldbname.sql
# md5sum $DB_BKP$filename.$mdldbname.sql > $DB_BKP$filename.$mdldbname.sql.md5
# md5sum -c $DB_BKP$filename.$mdldbname.sql.md5

sudo -i -u postgres pg_dump $mdldbname | gzip > $DB_BKP$filename.psql.gz
md5sum $DB_BKP$filename.psql.gz > $DB_BKP$filename.psql.gz.md5
md5sum -c $DB_BKP$filename.psql.gz.md5

# Backup the files using tar.
# tar -czf $DB_BKP$filename.tar.gz $MOODLE_DB
# md5sum $DB_BKP$filename.tar.gz > $DB_BKP$filename.tar.gz.md5
# md5sum -c $DB_BKP$filename.tar.gz.md5

# Backup the files using tar.
# tar -czf $HTML_BKP$filename.tar.gz $MOODLE_HOME
# md5sum $HTML_BKP$filename.tar.gz > $HTML_BKP$filename.tar.gz.md5
# md5sum -c $HTML_BKP$filename.tar.gz.md5

# Backup the files using tar.
tar -C $MOODLE_DATA -czf $DATA_BKP$filename.tar.gz cache filedir lang localcache muc temp trashdir
md5sum $DATA_BKP$filename.tar.gz > $DATA_BKP$filename.tar.gz.md5
md5sum -c $DATA_BKP$filename.tar.gz.md5

ls -lh -t $DATA_BKP

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable
