# moodle-update-script
- https://docs.moodle.org/38/en/Administration_via_command_line
- https://www.vogella.com/tutorials/GitSubmodules/article.html
- https://docs.moodle.org/38/en/Git_for_Administrators

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
https://docs.moodle.org/311/en/Cron

https://crontab.guru/
```bash
sudo crontab -u www-data -e
```
Add the line:
```bash
*/1 * * * * /usr/bin/php  /var/www/html/moodle/admin/cli/cron.php >/dev/null
```
