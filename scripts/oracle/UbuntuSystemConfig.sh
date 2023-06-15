#!/bin/bash

echo "Update and Upgrade System..."
sudo apt-get update 
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef


echo "Autoremove and Autoclean System..."
sudo apt-get autoremove -y && sudo apt-get autoclean -y

echo "Config SSH..."
sudo nano ~/.ssh/authorized_keys
sudo nano /etc/ssh/sshd_config
sudo service ssh restart

echo "Add locales pt_BR, en_US, es_ES, pt_PT..."
sudo sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
sudo sed -i '/^#.* en_AU.* /s/^#//' /etc/locale.gen
sudo locale-gen

echo "Set timezone and locale..." 
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot

# https://www.edivaldobrito.com.br/adicionar-a-swap-no-ubuntu/
echo "Add swap file..." 
sudo swapon -s
sudo fallocate -l 2G /swapfile
chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

sudo swapon -s
sudo nano /etc/fstab
/swapfile   none    swap    sw    0   0

echo "Change hostname..." 
sudo nano /etc/hostname
sudo nano /etc/hosts

echo "Get Jenkins Scripts..." 
mkdir scripts
cd scripts
wget https://raw.githubusercontent.com/AdrianoRuseler/moodle-update-script/master/scripts/jenkins/UpdateScripts.sh -O UpdateScripts.sh
chmod a+x UpdateScripts.sh
./UpdateScripts.sh

echo "Add the following Apache2 PPA repository"
sudo add-apt-repository ppa:ondrej/apache2 -y && sudo apt-get update
sudo apt install apache2
sudo a2enmod ssl rewrite headers deflate
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save

export LOCALSITENAME="mysite"
# export SITETYPE="PHP"
./CreateApacheSite.sh
# cp /var/www/html/index.html /var/www/html/$LOCALSITENAME/index.html
sudo nano /etc/apache2/sites-available/000-default.conf

RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

# https://certbot.eff.org/instructions?ws=apache&os=ubuntufocal
sudo snap install core; sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot --apache


# Jenkins JOBs - Slave
# https://www.jenkins.io/doc/book/using/using-agents/
sudo apt-get install fontconfig openjdk-11-jre

useradd -d /var/lib/jenkins jenkins
mkdir -p /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/authorized_keys
touch /var/lib/jenkins/.ssh/known_hosts

chown -R jenkins /var/lib/jenkins/.ssh
chmod 600 /var/lib/jenkins/.ssh/authorized_keys
chmod 700 /var/lib/jenkins/.ssh

cd /var/lib/jenkins/.ssh
ssh-keygen -t rsa -f jenkins_agent
cat jenkins_agent.pub >> authorized_keys
cat jenkins_agent.pub >> /root/.ssh/authorized_keys

ssh-keyscan -H adrianoruseler.com >> /var/lib/jenkins/.ssh/known_hosts # Master
ssh-keyscan -H adrianoruseler.com >> /root/.ssh/known_hosts # Master

cat jenkins_agent # OPENSSH PRIVATE KEY


ssh-keyscan -H mysql.adrianoruseler.com >> /var/lib/jenkins/.ssh/known_hosts # Slave

ssh -i mysql_jenkins_agent root@mysql.adrianoruseler.com


# Install MariaDB Server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
sudo apt-get install mariadb-server

# mariadb.service - MariaDB 11.0.2 database server
# https://docs.moodle.org/402/en/MySQL
nano /etc/mysql/my.cnf

[client]
default-character-set = utf8mb4

[mysqld]
innodb_file_format = Barracuda   # Remove line if not needed
innodb_file_per_table = 1
innodb_large_prefix = 1          # Remove line if not needed

character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
skip-character-set-client-handshake

[mysql]
default-character-set = utf8mb4

systemctl restart mariadb


# GitHub 
# https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent