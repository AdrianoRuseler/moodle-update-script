#!/bin/bash

# cat /var/log/cloud-init-output.log
echo "#1 - Initial system setup"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -yq

echo "Autoremove and Autoclean System..."
apt autoremove -yq && apt autoclean -yq

# Set timezone and locale
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot

# Instalar a AWS CLI versão 2 no Linux -> https://docs.aws.amazon.com/pt_br/cli/latest/userguide/install-cliv2-linux.html
cd /home/ubuntu
apt install -y unzip # p7zip-full
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
rm -rf awscliv2.zip
sudo ./aws/install
aws --version

# Install docker
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

docker-compose --version




# https://stackoverflow.com/questions/49859066/keycloak-docker-https-required/49874353
docker run --name keycloak -e KEYCLOAK_USER=myadmin -e KEYCLOAK_PASSWORD=mypassword -p 8443:8443 --detach jboss/keycloak
  
docker run -p 6443:443 --env PHPLDAPADMIN_LDAP_HOSTS=localhost --detach osixia/phpldapadmin:0.9.0
		
docker run --env LDAP_ORGANISATION="My Company" --env LDAP_DOMAIN="localhost" \
--env LDAP_ADMIN_PASSWORD="JonSn0w" --detach osixia/openldap:1.4.0



# sudo docker run -dit -p 8080:80 httpd:latest

# Gets public hostname 
PUBHOST=$(ec2metadata --public-hostname | cut -d : -f 2 | tr -d " ")
PUBIP=$(ec2metadata --public-ipv4 | cut -d : -f 2 | tr -d " ")
# Clone repos
git clone --depth=1 --branch MOODLE_39_STABLE git://git.moodle.org/moodle.git moodle
git clone --depth=1 https://github.com/moodlehq/moodle-docker.git moodle-docker

cd moodle-docker
sed -i 's/127.0.0.1/'"$PUBIP"'/' bin/moodle-docker-compose #
sed -i 's/127.0.0.1/'"$PUBIP"'/' bin/moodle-docker-compose.cmd #


# Set up path to Moodle code
export MOODLE_DOCKER_WWWROOT=/home/ubuntu/moodle

export MOODLE_DOCKER_WEB_HOST=$PUBHOST
export MOODLE_DOCKER_WEB_PORT=8083
# Choose a db server (Currently supported: pgsql, mariadb, mysql, mssql, oracle)
export MOODLE_DOCKER_DB=pgsql
export MOODLE_DOCKER_PHP_VERSION=7.4

# Ensure customized config.php for the Docker containers is in place
cp config.docker-template.php $MOODLE_DOCKER_WWWROOT/config.php

# Start up containers
bin/moodle-docker-compose up -d

# Wait for DB to come up (important for oracle/mssql)
bin/moodle-docker-wait-for-db

docker container ls
docker network ls

# Initialize Moodle database for manual testing
bin/moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Docker moodle" --shortname="docker_moodle" --adminpass="test" --adminemail="admin@example.com"







# Access into a container
docker exec -it moodle-docker_webserver_1 bash


# Work with the containers (see below)

# Show docker containers and their IP addresses
# docker ps -q | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} {{ .Name }}'

# Show docker containers and their MAC addresses
# docker ps -q | xargs -n 1 docker inspect --format '{{range .NetworkSettings.Networks}}{{.MacAddress}}{{end}} {{ .Name }}'


# bin/moodle-docker-compose exec webserver php admin/cli/maintenance.php --disable






sudo -u www-data /usr/bin/php admin/cli/maintenance.php --disable




# Initialize phpunit environment
bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php

# Initialize behat environment
bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php


# Shut down and destroy containers
bin/moodle-docker-compose down

