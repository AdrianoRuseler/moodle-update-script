#!/bin/bash

## https://moodledev.io/general/releases

# for php8.3
FOLDERS=('mdl44' 'mdl45' 'integration' 'sophia')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php8.3 /var/www/html/"$MDLFOLDER"/admin/cli/cron.php >/dev/null
done

# for php8.2
FOLDERS=('mdl42' 'mdl43' 'oficina')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php8.2 /var/www/html/"$MDLFOLDER"/admin/cli/cron.php >/dev/null
done

# for php8.1
FOLDERS=('mdl41')
for MDLFOLDER in "${FOLDERS[@]}"; do
  sudo -u www-data /usr/bin/php8.1 /var/www/html/"$MDLFOLDER"/admin/cli/cron.php >/dev/null
done
