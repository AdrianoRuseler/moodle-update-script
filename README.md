# moodle-update-script
https://docs.moodle.org/37/en/Administration_via_command_line
https://www.vogella.com/tutorials/GitSubmodules/article.html

# todo
- https://raymii.org/s/tutorials/Silent-automatic-apt-get-upgrade.html

## Script for Moodle install
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37install.sh
chmod u+x Moodle37install.sh

./Moodle37install.sh
 ```
 wget -O - https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37install.sh | sudo bash
 
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle35install.sh
chmod u+x Moodle35install.sh

./Moodle35install.sh
 ```

## Script for Debian/Ubuntu Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/DebianSystemConfig.sh -O DebianSystemConfig.sh
chmod u+x DebianSystemConfig.sh

 ./DebianSystemConfig.sh | tee DebianSystemConfig.log
 ```

## Script for Moodle Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37update.sh -O Moodle37update.sh
chmod u+x Moodle37update.sh

./Moodle37update.sh | tee Moodle37update.log
```
```bash
 wget -O - https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37update.sh | sudo bash
 ```
 
 ```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle35update.sh -O Moodle35update.sh
chmod u+x Moodle35update.sh

./Moodle35update.sh | tee Moodle35update.log
```
 
  ```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle35updategit.sh -O Moodle35updategit.sh
chmod u+x Moodle35updategit.sh

./Moodle35updategit.sh | tee Moodle35updategit.log
```
 
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
