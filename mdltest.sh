#sudo systemctl start docker
git clone --depth=50 --branch=master https://github.com/AdrianoRuseler/moodle-docker.git moodle-docker


#Setting environment variables

export PHP=7.3
export DB=pgsql
export GIT=master
export SUITE=phpunit-full

bash -c 'echo $BASH_VERSION'

git clone --branch $GIT --depth 1 git://github.com/moodle/moodle $HOME/moodle

cd moodle-docker

cp config.docker-template.php $HOME/moodle/config.php
#cp composer.json $HOME/moodle/composer.json
#cp composer.lock $HOME/moodle/composer.lock

export MOODLE_DOCKER_DB=$DB
export MOODLE_DOCKER_BROWSER=$BROWSER
export MOODLE_DOCKER_WWWROOT="$HOME/moodle"
export MOODLE_DOCKER_PHP_VERSION=$PHP

# Start up containers
bin/moodle-docker-compose up -d

# Wait for DB to come up (important for oracle/mssql)
bin/moodle-docker-wait-for-db

# Work with the containers (see below)
composer update
tests/setup.sh

tests/test.sh


# Shut down and destroy containers
bin/moodle-docker-compose down


