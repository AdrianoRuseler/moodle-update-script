# moodle-update-script
- https://docs.moodle.org/400/en/Administration_via_command_line
- https://www.vogella.com/tutorials/GitSubmodules/article.html
- https://docs.moodle.org/400/en/Git_for_Administrators

## Debian Config
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/DebianSystemConfig.sh -O DebianSystemConfig.sh
chmod u+x DebianSystemConfig.sh
sudo ./DebianSystemConfig.sh | tee DebianSystemConfig.log
```

## Script for Moodle Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle311update.sh -O Moodle311update.sh
chmod u+x Moodle311update.sh

sudo ./Moodle311update.sh | tee Moodle311update.log
```

## Script for Apache
```bash
# https://docs.moodle.org/400/en/Apache
# The function slash arguments is required for various features 
# in Moodle to work correctly, as described in Using slash arguments. 
AcceptPathInfo On
				
# This enables missing files to be themed by Moodle 
ErrorDocument 404 /error/index.php
 
# This sends any 403 from apache through to the same page, but also
# overrides the http status with 404 instead for better security.
ErrorDocument 403 /error/index.php?code=404
				
# Hiding internal paths
RewriteEngine On
 
RewriteRule "(\/vendor\/)" - [F]
RewriteRule "(\/node_modules\/)" - [F]
RewriteRule "(^|/)\.(?!well-known\/)" - [F]
RewriteRule "(composer\.json)" - [F]
RewriteRule "(\.lock)" - [F]
RewriteRule "(\/environment.xml)" - [F]
Options -Indexes
RewriteRule "(\/install.xml)" - [F]
RewriteRule "(\/README)" - [F]
RewriteRule "(\/readme)" - [F]
RewriteRule "(\/moodle_readme)" - [F]
RewriteRule "(\/upgrade\.txt)" - [F]
RewriteRule "(phpunit\.xml\.dist)" - [F]
RewriteRule "(\/tests\/behat\/)" - [F]
RewriteRule "(\/fixtures\/)" - [F]
```

## Test some plugins
- https://plugins.moodlebites.com/
- https://www.moodlebites.com/


## 
```php
// Use the following flag to completely disable the installation of plugins
// (new plugins, available updates and missing dependencies) and related
// features (such as cancelling the plugin installation or upgrade) via the
// server administration web interface.
$CFG->disableupdateautodeploy = true;
// Disabling update notifications
$CFG->disableupdatenotifications = true;

// Some administration options allow setting the path to executable files. This can
// potentially cause a security risk. Set this option to true to disable editing
// those config settings via the web. They will need to be set explicitly in the
// config.php file
// $CFG->preventexecpath = true;
```
## crontab
https://docs.moodle.org/400/en/Cron

https://crontab.guru/
```bash
sudo crontab -u www-data -e
```
Add the line:
```bash
*/1 * * * * /usr/bin/php  /var/www/html/moodle/admin/cli/cron.php >/dev/null
```
