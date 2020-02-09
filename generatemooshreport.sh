 
 
 courseid=2
 userid=3
 sectionid=1
 

 
 mdlrelease=$(moosh -n config-get core release)
 moosh -n course-config-set course 1 shortname "$mdlrelease"
  
 forumid=$(moosh -n activity-add --name "Moodle $mdlrelease - Report at $(date)" -o="--intro=Moodle version $mdlrelease - Reported at $(date)." --section $sectionid forum $courseid)

 courseusers=$(moosh -n user-list --course $courseid)
 moosh -n forum-newdiscussion --subject "Users in this Course" --message "<pre>$courseusers</pre>" $courseid $forumid $userid
 
 mdlpluginsusage=$(moosh -n plugins-usage)
 moosh -n forum-newdiscussion --subject "Plugins Usage - Shows the usage of the subset of the plugins used in Moodle installation." --message "<pre>$mdlpluginsusage</pre>" $courseid $forumid $userid

 datastats=$(moosh -n data-stats)
 moosh -n forum-newdiscussion --subject "Data Stats - Provides information on size of dataroot directory, dataroot/filedir subdirectory and total size of non-external files in moodle." --message "<pre>$datastats</pre>" $courseid $forumid $userid

 coreconfig=$(moosh -n config-get)
 moosh -n forum-newdiscussion --subject "Config - Get config variable from config or config_plugins table." --message "<pre>$coreconfig</pre>" $courseid $forumid $userid

 courselist=$(moosh -n course-list)
 moosh -n forum-newdiscussion --subject "Course List - Lists courses that match your search criteria." --message "<pre>$courselist</pre>" $courseid $forumid $userid

 eventlist=$(moosh -n event-list)
 moosh -n forum-newdiscussion --subject "Event List - List all events available in current Moodle installation." --message "<pre>$eventlist</pre>" $courseid $forumid $userid

 datacheck=$(moosh -n file-datacheck)
 moosh -n forum-newdiscussion --subject "File Datacheck - Go through all files in Moodle data and check them for corruption." --message "<pre>$datacheck</pre>" $courseid $forumid $userid

 dbcheck=$(moosh -n file-dbcheck)
 moosh -n forum-newdiscussion --subject "File dbcheck - Check that all files recorder in the DB do exist in Moodle data directory." --message "<pre>$dbcheck</pre>" $courseid $forumid $userid

 infoplugins=$(moosh -n info-plugins)
 moosh -n forum-newdiscussion --subject "info plugins - List all possible plugins in this version of Moodle and directory for each." --message "<pre>$infoplugins</pre>" $courseid $forumid $userid

 nowdate=$(date '+%Y%m%d')
 lastweek=$(date +%Y%m%d -d "7 day ago")
 concurrency=$(moosh -n report-concurrency -f $lastweek -t $nowdate -p 30)
 moosh -n forum-newdiscussion --subject "Report Concurrency - Get information about concurrent users online." --message "<pre>$concurrency</pre>" $courseid $forumid $userid

 themeinfo=$(moosh -n theme-info)
 moosh -n forum-newdiscussion --subject "Theme Info - Show what themes are really used on Moodle site." --message "<pre>$themeinfo</pre>" $courseid $forumid $userid


 authlist=$(moosh -n auth-list)
 moosh -n forum-newdiscussion --subject "Auth List - List authentication plugins." --message "<pre>$authlist</pre>" $courseid $forumid $userid

 categorylist=$(moosh -n category-list)
 moosh -n forum-newdiscussion --subject "Category List - List all categories or those that match search string(s)." --message "<pre>$categorylist</pre>" $courseid $forumid $userid



