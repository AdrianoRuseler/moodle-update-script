HTML_HOME="/var/www/html"
MOODLE_HOME="/var/www/html/moodle37"
MOODLE_DATA="/var/www/moodle37data"
TMP_DIR="/tmp"

cd $TMP_DIR
echo "Download Moodle..."
wget https://download.moodle.org/download.php/direct/stable37/moodle-latest-37.tgz -O moodle-latest-37.tgz
if [[ $? -ne 0 ]] ; then
    exit 1
fi
echo "Download OK..."

echo "Download Plugins..."
git clone https://github.com/AdrianoRuseler/moodle-plugins.git
cd moodle-plugins
git submodule update --init --recursive
cd ..
mv moodle-plugins/moodle moodle

echo "Extract Moodle 37..."
tar xvzf moodle-latest-37.tgz

echo "Clean files..."
rm -rf moodle-latest-37.tgz moodle-plugins

# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
sleep 30 # wait 30 secs

echo "Kill all user sessions...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs
echo "Moodle Maintenance Mode Activated...";

echo "moving old files ..."
sudo mv $MOODLE_HOME $MOODLE_HOME.bkp

echo "moving new files ..."
sudo mv $TMP_DIR/moodle $MOODLE_HOME

echo "copying config file ..."
sudo cp $MOODLE_HOME.bkp/config.php $MOODLE_HOME

echo "fixing file permissions ..."
sudo chmod 740 $MOODLE_HOME/admin/cli/cron.php
sudo chown www-data:www-data -R $MOODLE_HOME 

echo "Upgrading Moodle Core started..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/upgrade.php --non-interactive

echo "purge Moodle cache ..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/purge_caches.php

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable

echo "compress moddle backup directory ..."
sudo tar -zcvf $MOODLE_HOME.bkp.tar.gz $MOODLE_HOME.bkp
sudo rm -rf $MOODLE_HOME.bkp





