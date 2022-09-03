# README.md
```bash
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/SystemSetup.sh -O SystemSetup.sh
chmod a+x SystemSetup.sh
./SystemSetup.sh
```
## Get scripts
```bash
mkdir scripts
cd scripts
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/UpdateScripts.sh -O UpdateScripts.sh
chmod a+x UpdateScripts.sh
./UpdateScripts.sh
```
## Install phpMyAdmin
```bash
export LOCALSITENAME="pma"
export SITETYPE="PMA"
./CreateApacheLocalSite.sh
./InstallPMA.sh
```
## Install Moodle
```bash
export LOCALSITENAME="devtest"
export SITETYPE="MDL"
export MDLBRANCH="MOODLE_311_STABLE"
export MDLREPO="https://github.com/moodle/moodle.git"
./CreateApacheLocalSite.sh
./GetMDL.sh
./CreateDataBaseUser.sh
./InstallMDL.sh
./ConfigMDL.sh
```

