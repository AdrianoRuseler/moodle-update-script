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
wget https://github.com/AdrianoRuseler/moodle-plugins/archive/MOODLE_37_STABLE.zip -O MOODLE_37_PLUGINS_STABLE.zip
if [[ $? -ne 0 ]] ; then
    exit 1
fi
echo "Download OK..."

echo "Extract and move Plugins..."
unzip MOODLE_37_PLUGINS_STABLE.zip
mv moodle-plugins-MOODLE_37_STABLE/moodle moodle

echo "Extract Moodle 37..."
tar xvzf moodle-latest-37.tgz

echo "Clean files..."
rm -rf moodle-latest-37.tgz MOODLE_37_PLUGINS_STABLE.zip moodle-plugins-MOODLE_37_STABLE


# echo "Activating Moodle Maintenance Mode in...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --enablelater=1
sleep 30 # wait 30 secs

echo "Kill all user sessions...";
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/kill_all_sessions.php

sleep 30 # wait 30 secs

echo "Upgrading Moodle... NOT IMPLEMENTED!!"
sleep 30 # wait 30 secs

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MOODLE_HOME/admin/cli/maintenance.php --disable




