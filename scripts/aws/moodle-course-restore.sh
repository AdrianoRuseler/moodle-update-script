#!/bin/bash

# See: https://moosh-online.com/commands/#course-restore
categoryid=2 # category ID to restore courses

#MOODLE_HOME="/var/www/moodle/html" # moodle core folder
MOODLE_HOME="/var/www/moodledev/html" # moodle core folder

MBZBKP_DIR="/mnt/nvme1n1p1/mdlbkp/auto/" # moodle auto/backup folder
# MBZBKP_DIR="/mnt/nvme1n1p1/mdlbkpdev/auto" # moodle auto/backup folder


cd $MBZBKP_DIR # Change to backup folder
echo "Looking for mbz files in provided folder ($MBZBKP_DIR)!"
mbzlist=$(ls *.mbz) # Gets mbz files name

cd $MOODLE_HOME # Change to restore installation

for mbzfile in $mbzlist; do
courseid=$(echo $mbzfile | cut -d- -f4) # gets course ID
	if [[ $courseid -eq 1 ]]; then # Not restoring main course		
		echo "Skipping file $mbzfile with courseid = $courseid ..."
	else
		echo "Restoring file $mbzfile with courseid = $courseid ..."
		moosh -n course-restore $MBZBKP_DIR$mbzfile $categoryid
	fi
done
