#!/bin/bash

FOLDERS=('mdl39' 'mdl310' 'mdl311' 'mdl40' 'oficina' 'integration')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done

#*/1 * * * * /usr/bin/php  /var/www/html/oficina/admin/cli/cron.php >/dev/null
