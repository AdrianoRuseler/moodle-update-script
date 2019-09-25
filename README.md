# moodle-update-script
## Add locales pt_BR, en_US, es_ES, de_DE, fr_FR, pt_PT
```bash
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* es_ES.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* de_DE.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* fr_FR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* pt_PT.* /s/^#//' /etc/locale.gen
sudo locale-gen
```


## Script for Debian/Ubuntu Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/DebianSystemUpdate.sh -O DebianSystemUpdate.sh
chmod u+x DebianSystemUpdate.sh

./DebianSystemUpdate.sh
```

## Script for Moodle Update
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/Moodle37update.sh -O Moodle37update.sh
chmod u+x Moodle37update.sh

./Moodle37update.sh
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
https://crontab.guru/
