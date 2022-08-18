#!/bin/bash

courseid=2
userid=3
sectionid=1 
 
MOODLE_HOME="/var/www/moodle/html" # moodle core folder
MOODLE_DATA="/mnt/mdl/data" # moodle data folder
BKP_DIR="/mnt/mdl/bkp" # moodle backup folder

cd $MOODLE_HOME
 
mdlrelease=$(moosh -n config-get core release)
moosh -n course-config-set course 1 shortname "Moodle $mdlrelease"

echo "Create Forum:"
forumid=$(moosh -n activity-add --name "Moodle $mdlrelease - System Report at $(date)" -o="--intro=Moodle version $mdlrelease - $(date)." --section $sectionid forum $courseid)

# courseusers=$(moosh -n user-list --course $courseid)
# moosh -n forum-newdiscussion --subject "Users in this Course" --message "<pre>$courseusers</pre>" $courseid $forumid $userid

echo "Post - Plugins Usage" 
mdlpluginsusage=$(moosh -n plugins-usage)
moosh -n forum-newdiscussion --subject "Plugins Usage - Shows the usage of the subset of the plugins used in Moodle installation." --message "<pre>$mdlpluginsusage</pre>" $courseid $forumid $userid

echo "Post - Data Stats" 
datastats=$(moosh -n data-stats)
moosh -n forum-newdiscussion --subject "Data Stats - Provides information on size of dataroot directory." --message "<pre>$datastats</pre>" $courseid $forumid $userid

echo "Post - Plugins Usage"
mdldatastats=$(moosh -n data-stats)
moosh -n forum-newdiscussion --subject "Plugins Usage - Shows the usage of the subset of the plugins used in Moodle installation." --message "<pre>$mdldatastats</pre>" $courseid $forumid $userid

echo "Post - Core Config variables"
# coreconfig=$(moosh -n config-get)
moosh -n config-get core > /tmp/coreconfig.txt
# coreconfig=$(echo $coreconfig | sed -e "s/\[dbpass\] => [^[:space:]]*/\[dbpass\] => mysecretpass/g") # Hides db password
cat /tmp/coreconfig.txt | sed -e "s/\[dbpass\] => [^[:space:]]*/\[dbpass\] => mysecretpass/g" > /tmp/coreconfig2.txt
#coreconfig=$(echo $coreconfig | sed -e "s/\[smtppass\] => [^[:space:]]*/\[smtppass\] => mysecretpass/g") # Hides smtp password
cat /tmp/coreconfig2.txt | sed -e "s/\[smtppass\] => [^[:space:]]*/\[smtppass\] => mysecretpass/g" > /tmp/coreconfig3.txt
cat /tmp/coreconfig3.txt | sed -e "s/\[bigbluebuttonbn_shared_secret\] => [^[:space:]]*/\[bigbluebuttonbn_shared_secret\] => mysecretpass/g" > /tmp/coreconfig4.txt

coreconfig=$(cat /tmp/coreconfig4.txt)
rm -rf coreconfig.txt coreconfig1.txt coreconfig2.txt coreconfig3.txt coreconfig3.txt

moosh -n forum-newdiscussion --subject "Moodle core config - Get core config variables." --message "<pre>$coreconfig</pre>" $courseid $forumid $userid

echo "Post - Plugins Config List"
pluginsconfig=$(moosh -n config-plugins)
moosh -n forum-newdiscussion --subject "Plugins Config List - Get config variable from config_plugins table." --message "<pre>$pluginsconfig</pre>" $courseid $forumid $userid


echo "Post - Backup Config Variable"
bkpconfig=$(moosh -n config-get backup)
moosh -n forum-newdiscussion --subject "Backup Config Variables - Get config variable from config_plugins table." --message "<pre>$bkpconfig</pre>" $courseid $forumid $userid


echo "Post - Course List"
courselist=$(moosh -n course-list)
moosh -n forum-newdiscussion --subject "Course List - Lists courses that match your search criteria." --message "<pre>$courselist</pre>" $courseid $forumid $userid

echo "Post - Event List"
eventlist=$(moosh -n event-list)
moosh -n forum-newdiscussion --subject "Event List - List all events available in current Moodle installation." --message "<pre>$eventlist</pre>" $courseid $forumid $userid

echo "Post - File Datacheck"
datacheck=$(moosh -n file-datacheck)
moosh -n forum-newdiscussion --subject "File Datacheck - Go through all files in Moodle data and check them for corruption." --message "<pre>$datacheck</pre>" $courseid $forumid $userid

echo "Post - File dbcheck"
dbcheck=$(moosh -n file-dbcheck)
moosh -n forum-newdiscussion --subject "File dbcheck - Check that all files recorder in the DB do exist in Moodle data directory." --message "<pre>$dbcheck</pre>" $courseid $forumid $userid

echo "Post - Info Plugins"
infoplugins=$(moosh -n info-plugins)
moosh -n forum-newdiscussion --subject "Info Plugins - List all possible plugins in this version of Moodle and directory for each." --message "<pre>$infoplugins</pre>" $courseid $forumid $userid

# nowdate=$(date '+%Y%m%d')
# lastweek=$(date +%Y%m%d -d "7 day ago")
# concurrency=$(moosh -n report-concurrency -f $lastweek -t $nowdate -p 30)
# moosh -n forum-newdiscussion --subject "Report Concurrency (last Week)- Get information about concurrent users online." --message "<pre>$concurrency</pre>" $courseid $forumid $userid

echo "Post - Theme Info"
themeinfo=$(moosh -n theme-info)
moosh -n forum-newdiscussion --subject "Theme Info - Show what themes are really used on Moodle site." --message "<pre>$themeinfo</pre>" $courseid $forumid $userid

echo "Post - Auth List"
authlist=$(moosh -n auth-list)
moosh -n forum-newdiscussion --subject "Auth List - List authentication plugins." --message "<pre>$authlist</pre>" $courseid $forumid $userid

echo "Post - Category List"
categorylist=$(moosh -n category-list)
moosh -n forum-newdiscussion --subject "Category List - List all categories or those that match search string(s)." --message "<pre>$categorylist</pre>" $courseid $forumid $userid
 
# echo "Post - PHP Info"
# phpinfo=$(php -i)
# moosh -n forum-newdiscussion --subject "PHP Info" --message "<pre>$phpinfo</pre>" $courseid $forumid $userid
 
echo "Post - Moodle root/data info" 
moodlerootinfo1=$(ls -lh)
moodlerootinfo2=$(du -h --max-depth=1)

moodledatainfo3=$(ls -lh $MOODLE_DATA)
moodledatainfo4=$(du -h --max-depth=1 $MOODLE_DATA)

moosh -n forum-newdiscussion --subject "Moodle root/data info" --message "<pre>$moodlerootinfo1</pre><hr><pre>$moodlerootinfo2</pre><hr><pre>$moodlerootinfo3</pre><hr><pre>$moodlerootinfo4</pre>" $courseid $forumid $userid 

echo "Post - Moodle Backup info"
moodlebkpinfo1=$(ls -lh $BKP_DIR)
moodlebkpinfo2=$(du -h --max-depth=1 $BKP_DIR)

moosh -n forum-newdiscussion --subject "Moodle Backup info" --message "<hr><pre>$moodlebkpinfo1</pre><hr><pre>$moodlebkpinfo2</pre>" $courseid $forumid $userid 
  
echo "Post - System info"
sysinfo=$(uname -a) # Gets system info
diskinfo=$(df -H) # Gets disk usage info 
topreport=$(top -b -n 1)
httpdver=$(apachectl -V)
mysqlver=$(psql -V)
phpversion=$(php -v)

moosh -n forum-newdiscussion --subject "System info" --message "<hr><pre>$sysinfo</pre><hr><br><pre>$diskinfo</pre><hr><br><pre>$topreport</pre><hr><br><pre>$httpdver</pre><hr><br><pre>$mysqlver</pre><hr><br><pre>$phpversion</pre>" $courseid $forumid $userid

echo "Post - List of scheduled tasks"
# List of scheduled tasks 
# admin/tool/task/cli/schedule_task.php --list
sudo -u www-data /usr/bin/php admin/tool/task/cli/schedule_task.php --list > /tmp/scheduletasklist.txt

scheduletasklist=$(cat /tmp/scheduletasklist.txt)
moosh -n forum-newdiscussion --subject "List of scheduled tasks" --message "<h5>List of scheduled tasks</h5><pre>$scheduletasklist</pre>" $courseid $forumid $userid

# Change section and post all plugins settings
sectionid=2
echo "Create Forum for themes:"
forumid=$(moosh -n activity-add --name "Themes - Moodle $mdlrelease - $(date)" -o="--intro=Moodle version $mdlrelease - $(date)." --section $sectionid forum $courseid)

pluginsconfig=$(moosh -n config-plugins theme)
# Iterate the string variable using for loop
for val in $pluginsconfig; do
    echo $val
	pconfig=$(moosh -n config-get $val)
	moosh -n forum-newdiscussion --subject "$val" --message "<h3>moosh -n config-get $val</h3><hr><pre>$pconfig</pre>" $courseid $forumid $userid
done


forumid=$(moosh -n activity-add --name "Plugins Types - Moodle $mdlrelease - $(date)" -o="--intro=Moodle version $mdlrelease - $(date)." --section $sectionid forum $courseid)
list="cache data atto block book qtype quiz report workshop mod repository tinymce tool user url web resource auth enrol availability assign editor grade qbehaviour profile customcert filter"
for ptype in $list; do
	echo "Config Settings for $ptype..."
	plist=$(moosh -n config-plugins $ptype)
	strout=""
	for pval in $plist; do
		pconfig=$(moosh -n config-get $pval)
		strout="$strout<hr><h3>$pval</h3><hr><pre>$pconfig</pre>"
	done
	moosh -n forum-newdiscussion --subject "$ptype" --message "$strout" $courseid $forumid $userid
done


forumid=$(moosh -n activity-add --name "Backup/Restore - Moodle $mdlrelease - $(date)" -o="--intro=Moodle version $mdlrelease - $(date)." --section $sectionid forum $courseid)
list="restore backup"
for ptype in $list; do
	echo "Config Settings for $ptype..."
	plist=$(moosh -n config-plugins $ptype)
	strout=""
	for pval in $plist; do
		pconfig=$(moosh -n config-get $pval)
		strout="$strout<hr><h3>$pval</h3><hr><pre>$pconfig</pre>"
	done
	moosh -n forum-newdiscussion --subject "$ptype" --message "$strout" $courseid $forumid $userid
done

