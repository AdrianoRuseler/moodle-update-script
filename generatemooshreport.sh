 
 
 courseid=2
 userid=3
 sectionid=1
 

 
 mdlrelease=$(moosh -n config-get core release)
 moosh -n course-config-set course 1 shortname "$mdlrelease"
  
 forumid=$(moosh -n activity-add --name "Moodle $mdlrelease - Report at $(date)" -o="--intro=Moodle version $mdlrelease - Reported at $(date)." --section $sectionid forum $courseid)

 courseusers=$(moosh user-list --course $courseid)
 moosh -n forum-newdiscussion --subject "Users in this Course" --message "<pre>$courseusers</pre>" $courseid $forumid $userid
 
 mdlpluginsusage=$(moosh -n plugins-usage)
 moosh -n forum-newdiscussion --subject "Plugins Usage" --message "<pre>$mdlpluginsusage</pre>" $courseid $forumid $userid

 datastats=$(moosh -n data-stats)
 moosh -n forum-newdiscussion --subject "Data Stats" --message "<pre>$datastats</pre>" $courseid $forumid $userid

 coreconfig=$(moosh -n config-get)
 moosh -n forum-newdiscussion --subject "Core Config Stats" --message "Get config variable from config or config_plugins table. <pre>$coreconfig</pre>" $courseid $forumid $userid

 courselist=$(moosh -n course-list)
 moosh -n forum-newdiscussion --subject "Course List" --message "<pre>$courselist</pre>" $courseid $forumid $userid

 eventlist=$(moosh -n event-list)
 moosh -n forum-newdiscussion --subject "Event List" --message "<pre>$eventlist</pre>" $courseid $forumid $userid

 datacheck=$(moosh -n file-datacheck)
 moosh -n forum-newdiscussion --subject "File Datacheck" --message "<pre>$datacheck</pre>" $courseid $forumid $userid

 dbcheck=$(moosh -n file-dbcheck)
 moosh -n forum-newdiscussion --subject "File dbcheck" --message "<pre>$dbcheck</pre>" $courseid $forumid $userid

 infoplugins=$(moosh -n info-plugins)
 moosh -n forum-newdiscussion --subject "info plugins" --message "<pre>$infoplugins</pre>" $courseid $forumid $userid

 concurrency=$(moosh -n report-concurrency -f 20140120 -t 20140127 -p 30)
 moosh -n forum-newdiscussion --subject "report concurrency" --message "<pre>$concurrency</pre>" $courseid $forumid $userid

 themeinfo=$(moosh -n theme-info)
 moosh -n forum-newdiscussion --subject "Theme Info" --message "<pre>$themeinfo</pre>" $courseid $forumid $userid


 authlist=$(moosh -n auth-list)
 moosh -n forum-newdiscussion --subject "auth-list" --message "<pre>$authlist</pre>" $courseid $forumid $userid

 categorylist=$(moosh -n category-list)
 moosh -n forum-newdiscussion --subject "category-list" --message "<pre>$categorylist</pre>" $courseid $forumid $userid



