 
 
 courseid=2
 
 
 mdlrelease=$(moosh -n config-get core release)
 moosh -n course-config-set course 1 shortname "$mdlrelease"
  
 forumid=$(moosh -n activity-add --name "Moodle $mdlrelease" -o="--intro=Moodle version $mdlrelease updated in $(date)." --section 1 forum $courseid)



 mdlpluginsusage=$(moosh -n plugins-usage)
 moosh -n forum-newdiscussion --subject "Plugins Usage" --message "<pre>$mdlpluginsusage</pre>" $courseid $forumid 3

 datastats=$(moosh -n data-stats)
 moosh -n forum-newdiscussion --subject "Data Stats" --message "<pre>$datastats</pre>" $courseid $forumid 3

 coreconfig=$(moosh -n config-get)
 moosh -n forum-newdiscussion --subject "Core Config Stats" --message "Get config variable from config or config_plugins table. <pre>$coreconfig</pre>" $courseid $forumid 3

 courselist=$(moosh -n course-list)
 moosh -n forum-newdiscussion --subject "Course List" --message "<pre>$courselist</pre>" $courseid $forumid 3

 eventlist=$(moosh -n event-list)
 moosh -n forum-newdiscussion --subject "Event List" --message "<pre>$eventlist</pre>" $courseid $forumid 3

 datacheck=$(moosh -n file-datacheck)
 moosh -n forum-newdiscussion --subject "File Datacheck" --message "<pre>$datacheck</pre>" $courseid $forumid 3

 dbcheck=$(moosh -n file-dbcheck)
 moosh -n forum-newdiscussion --subject "File dbcheck" --message "<pre>$dbcheck</pre>" $courseid $forumid 3

 infoplugins=$(moosh -n info-plugins)
 moosh -n forum-newdiscussion --subject "info plugins" --message "<pre>$infoplugins</pre>" $courseid $forumid 3

 concurrency=$(moosh -n report-concurrency -f 20140120 -t 20140127 -p 30)
 moosh -n forum-newdiscussion --subject "report concurrency" --message "<pre>$concurrency</pre>" $courseid $forumid 3

 themeinfo=$(moosh -n theme-info)
 moosh -n forum-newdiscussion --subject "Theme Info" --message "<pre>$themeinfo</pre>" $courseid $forumid 3

 # passwords=$(moosh -n audit-passwords -r)
 # moosh -n forum-newdiscussion --subject "audit passwords" --message "<pre>$passwords</pre>" $courseid $forumid 3

 authlist=$(moosh -n auth-list)
 moosh -n forum-newdiscussion --subject "auth-list" --message "<pre>$authlist</pre>" $courseid $forumid 3

 categorylist=$(moosh -n category-list)
 moosh -n forum-newdiscussion --subject "category-list" --message "<pre>$categorylist</pre>" $courseid $forumid 3



