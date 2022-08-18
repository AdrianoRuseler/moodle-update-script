# Docker is installed

# Clone repos
git clone --depth=1 --branch MOODLE_39_STABLE git://git.moodle.org/moodle.git moodle
git clone --depth=1 https://github.com/moodlehq/moodle-docker.git moodle-docker

cd moodle-docker
# Set up path to Moodle code
export MOODLE_DOCKER_WWWROOT=/home/docker/moodle
# export MOODLE_DOCKER_WEB_HOST=
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

# Initialize phpunit environment
bin/moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php

# Initialize behat environment
bin/moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php

