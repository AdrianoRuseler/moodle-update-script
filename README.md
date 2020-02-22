# moodle-update-script
- https://docs.moodle.org/37/en/Administration_via_command_line
- https://www.vogella.com/tutorials/GitSubmodules/article.html


## Script for Moodle Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37update.sh -O Moodle37update.sh
chmod u+x Moodle37update.sh

./Moodle37update.sh | tee Moodle37update.log
```

```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/moodle37dev.sh -O Moodle37dev.sh
chmod u+x Moodle37dev.sh

./Moodle37dev.sh | tee -a Moodle37dev.log
```

## Test some plugins
https://plugins.moodlebites.com/
https://www.moodlebites.com/


## 
```php
// Use the following flag to completely disable the installation of plugins
// (new plugins, available updates and missing dependencies) and related
// features (such as cancelling the plugin installation or upgrade) via the
// server administration web interface.
$CFG->disableupdateautodeploy = true;
// Disabling update notifications
$CFG->disableupdatenotifications = true;
```
## crontab
https://docs.moodle.org/37/en/Cron

https://crontab.guru/
```bash
sudo crontab -u www-data -e
```
Add the line:
```bash
*/1 * * * * /usr/bin/php  /var/www/html/moodle/admin/cli/cron.php >/dev/null
```
