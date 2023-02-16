#!/bin/bash

FOLDERS=('mdl311' 'mdl40' 'mdl41' 'oficina' 'integration' 'sophia')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done

FOLDERS=('mdl39' 'mdl310' )
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php7.4 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done


FOLDERS=('mdl35' )
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php7.2 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done