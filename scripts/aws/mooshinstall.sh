#!/bin/bash

echo "#5 - Install Moosh"
cd /var/www/moodle/git
# https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
echo "Download composer-setup.php ..."
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

echo "Verify composer-setup.php ..."
if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
	exit 1
fi

echo "Install composer-setup.php ..."
php composer-setup.php --quiet
rm composer-setup.php

echo "Move conposer.phar"
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer
composer --version

# https://moosh-online.com/
echo "Clone moosh"
git clone git://github.com/tmuras/moosh.git
cd moosh
echo "Composer install moosh"
composer install
ln -s $PWD/moosh.php /usr/local/bin/moosh

echo "Create moosh user and report course"
cd /var/www/moodle/html
MOOSHPASS=$(pwgen -s 14 1) # Generates ramdon password for Moosh User
userid=$(moosh -n user-create --password $MOOSHPASS --email moosh@fake.mail --city Curitiba --country BR --firstname Moosh --lastname User moosh)
courseid=$(moosh -n course-create --category 1 --fullname "Moosh Reports" --description "Moosh command line reports" --idnumber "mooshreports" "Moosh Reports")
moosh -n course-enrol -r teacher -i $courseid $userid

sectionid=0 # Set section number

mdlrelease=$(moosh -n config-get core release)
forumid=$(moosh -n activity-add --name "Reports from cloud-init-output.log" -o="--intro=Moodle version $mdlrelease - $(date)." --section $sectionid forum $courseid)

# Generates split logs files
sed -n "/Cloud-init.*/, /#1.*/ p"  /var/log/cloud-init-output.log >> /tmp/log01.log
sed -n "/#1.*/, /#2.*/ p"  /var/log/cloud-init-output.log >> /tmp/log02.log
sed -n "/#2.*/, /#3.*/ p"  /var/log/cloud-init-output.log >> /tmp/log03.log
sed -n "/#3.*/, /#4.*/ p"  /var/log/cloud-init-output.log >> /tmp/log04.log
sed -n "/#4.*/, /#5.*/ p"  /var/log/cloud-init-output.log >> /tmp/log05.log
sed -n "/#5.*/, /Cloud-init.*/ p"  /var/log/cloud-init-output.log >> /tmp/log06.log


cloudlog1=$(cat /tmp/log01.log) # Reads file content
moosh -n forum-newdiscussion --subject "Initial Cloud-init setup" --message "<pre>$cloudlog1</pre>" $courseid $forumid $userid

cloudlog2=$(cat /tmp/log02.log) # Reads file content
moosh -n forum-newdiscussion --subject "Initial system setup and update" --message "<pre>$cloudlog2</pre>" $courseid $forumid $userid

cloudlog3=$(cat /tmp/log03.log) # Reads file content
moosh -n forum-newdiscussion --subject "Web server and dependencies setup" --message "<pre>$cloudlog3</pre>" $courseid $forumid $userid

cloudlog4=$(cat /tmp/log04.log) # Reads file content
moosh -n forum-newdiscussion --subject "Tools and dependencies setup" --message "<pre>$cloudlog4</pre>" $courseid $forumid $userid

cloudlog5=$(cat /tmp/log05.log) # Reads file content
moosh -n forum-newdiscussion --subject "Install Moodle" --message "<pre>$cloudlog5</pre>" $courseid $forumid $userid

cloudlog6=$(cat /tmp/log06.log) # Reads file content
moosh -n forum-newdiscussion --subject "Install Moosh" --message "<pre>$cloudlog6</pre>" $courseid $forumid $userid

