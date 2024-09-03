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
## Moodle Plugins Repos
- https://github.com/AdrianoRuseler/moodle401-plugins
- https://github.com/AdrianoRuseler/moodle402-plugins
- https://github.com/AdrianoRuseler/moodle403-plugins
- https://github.com/AdrianoRuseler/moodle404-plugins

  
## Moodle Update
```bash
export MDLREPO="https://github.com/moodle/moodle.git"
export MDLBRANCH="MOODLE_404_STABLE"  # GIT Branch for moodle core
export MDLCORE="mdlcore" # Temp folder for moodle core
export PLGREPO="https://github.com/AdrianoRuseler/moodle404-plugins.git"
export PLGBRANCH="main" # GIT Branch for moodle plugins
export MDLPLGS="mdlplugins" # Temp folder for moodle plugins
# Moodle software (For example, everything in server/htdocs/moodle)
export MDLHOME="path/to/moodle" # TODO!

cd /tmp
git clone --depth=1 --branch=$MDLBRANCH $MDLREPO $MDLCORE
git clone --depth=1 --recursive --branch=$PLGBRANCH $PLGREPO $MDLPLGS
sudo rsync -a /tmp/$MDLPLGS/moodle/* /tmp/$MDLCORE/
	
echo "Moving old files ..."
sudo mv $MDLHOME $MDLHOME.tmpbkp
mkdir $MDLHOME

echo "moving new files..."
sudo mv /tmp/$MDLCORE/* $MDLHOME

echo "Copying config file ..."
sudo cp $MDLHOME.tmpbkp/config.php $MDLHOME

echo "Remove tmp files..."
sudo rm -rf /tmp/$MDLPLGS
sudo rm -rf /tmp/$MDLCORE
```

## Script for Apache
- https://docs.moodle.org/400/en/Apache
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


## Configuration file
- https://docs.moodle.org/400/en/Configuration_file
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
$CFG->preventexecpath = true;
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
