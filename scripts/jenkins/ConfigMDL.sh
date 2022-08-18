#!/bin/bash

# Load Environment Variables in .env file
if [ -f .env ]; then	
	export $(grep -v '^#' .env | xargs)
fi

# Verify for LOCALSITENAME
if [[ ! -v LOCALSITENAME ]] || [[ -z "$LOCALSITENAME" ]]; then
    echo "LOCALSITENAME is not set or is set to the empty string"
    echo "Choose site to use:"
	ls /etc/apache2/sites-enabled/
	echo "export LOCALSITENAME="
    exit 1
else
    echo "LOCALSITENAME has the value: $LOCALSITENAME"	
fi

ENVFILE='.'${LOCALSITENAME}'.env'
SCRIPTDIR=$(pwd)
if [ -f $ENVFILE ]; then
	# Load Environment Variables
	export $(grep -v '^#' $ENVFILE | xargs)
	echo ""
	echo "##------------ $ENVFILE -----------------##"
	cat $ENVFILE
	echo "##------------ $ENVFILE -----------------##"
	echo ""
fi

# Verify for MDLHOME
if [[ ! -v MDLHOME ]] || [[ -z "$MDLHOME" ]]; then
    echo "MDLHOME is not set or is set to the empty string!"
    exit 1
else
    echo "MDLHOME has the value: $MDLHOME"	
fi

mdlver=$(cat $MDLHOME/version.php | grep '$release' | cut -d\' -f 2) # Gets Moodle Version
echo "Moodle "$mdlver

echo "Enable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --enable

echo "Setting configurations..."
# sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=theme --set=classic
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowthemechangeonurl --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowuserthemes --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowcoursethemes --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowcategorythemes --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=allowcohortthemes --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=downloadcoursecontentallowed --set=1
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=lang --set=en
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/cfg.php --name=doclang --set=en

# Install H5P content
sudo -u www-data /usr/bin/php $MDLHOME/admin/tool/task/cli/schedule_task.php --execute='\core\task\h5p_get_content_types_task'

echo "disable the maintenance mode..."
sudo -u www-data /usr/bin/php $MDLHOME/admin/cli/maintenance.php --disable




