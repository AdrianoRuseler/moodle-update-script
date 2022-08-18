## EC2 User Data
- https://docs.aws.amazon.com/pt_br/AWSEC2/latest/UserGuide/user-data.html
```bash
#!/bin/bash

# Installs Moodle - https://moodle.org
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/userdata-test-ubuntu.sh
chmod u+x userdata-test-ubuntu.sh
sudo ./userdata-test-ubuntu.sh

# Installs Moosh - https://moosh-online.com/
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/mooshinstall.sh
chmod u+x mooshinstall.sh
sudo ./mooshinstall.sh

# Creates system backup
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/moodle-backup.sh
chmod u+x moodle-backup.sh
sudo ./moodle-backup.sh

# Runs Moosh Report
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/generatemooshreport.sh
chmod u+x generatemooshreport.sh
sudo ./generatemooshreport.sh
```

## Reset Installation

```bash
#!/bin/bash

# Reset Moodle - https://moodle.org
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/moodle-reset.sh
chmod u+x moodle-reset.sh
sudo ./moodle-reset.sh
```


## Restore Installation

```bash
#!/bin/bash

# Restore Moodle - https://moodle.org
wget https://raw.githubusercontent.com/AdrianoRuseler/mdlmooc-plugins/master/scripts/test/moodle-restore.sh
chmod u+x moodle-restore.sh
sudo ./moodle-restore.sh
```
