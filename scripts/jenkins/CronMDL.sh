#!/bin/bash

#*/1 * * * * /usr/bin/php8.1  /var/www/html/mdl41/admin/cli/cron.php >/dev/null
#*/1 * * * * /usr/bin/php8.1  /var/www/html/mdl42/admin/cli/cron.php >/dev/null
#*/1 * * * * /usr/bin/php8.1  /var/www/html/integration/admin/cli/cron.php >/dev/null
#*/1 * * * * /usr/bin/php8.1  /var/www/html/sophia/admin/cli/cron.php >/dev/null
#*/1 * * * * /usr/bin/php8.1  /var/www/html/oficina/admin/cli/cron.php >/dev/null

FOLDERS=('mdl41' 'mdl42' 'oficina' 'integration' 'sophia')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php8.1 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done

#*/1 * * * * /usr/bin/php8.0  /var/www/html/mdl40/admin/cli/cron.php >/dev/null
#*/1 * * * * /usr/bin/php8.0  /var/www/html/mdl311/admin/cli/cron.php >/dev/null

FOLDERS=('mdl311' 'mdl40')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php8.0 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done

#*/1 * * * * /usr/bin/php7.4  /var/www/html/mdl39/admin/cli/cron.php >/dev/null

FOLDERS=('mdl39')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php7.4 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
done

#FOLDERS=('mdl35' )
#for MDLFOLDER in "${FOLDERS[@]}"; do
#  sudo -u www-data /usr/bin/php7.2 /var/www/html/$MDLFOLDER/admin/cli/cron.php >/dev/null
#done










