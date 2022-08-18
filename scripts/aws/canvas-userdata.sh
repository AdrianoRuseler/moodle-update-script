#!/bin/bash

# cat /var/log/cloud-init-output.log
echo "#1 - Initial system setup"
export DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -yq

echo "Set and Add locales pt_BR, en_US..."
sed -i '/^#.* pt_BR.* /s/^#//' /etc/locale.gen
sed -i '/^#.* en_US.* /s/^#//' /etc/locale.gen
locale-gen

# Set timezone and locale
timedatectl set-timezone America/Sao_Paulo
update-locale LANG=pt_BR.UTF-8 # Requires reboot

# Set EBS -> https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html
mkdir /mnt/canvas
mkfs -t xfs /dev/xvdb
mount -t xfs /dev/xvdb /mnt/canvas
mkdir -p /mnt/canvas/{db,data,bkp}
mkdir -p /mnt/canvas/bkp/{db,data,html,auto} # Creates backup folders

# Automatically mount an attached volume after reboot
cp /etc/fstab /etc/fstab.orig # Make backup
MNTUUID=$(lsblk -nr -o UUID,MOUNTPOINT | grep -Po '.*(?= /mnt/canvas)')
echo $'UUID='${MNTUUID}$' /mnt/canvas xfs defaults,nofail  0  2' >> /etc/fstab

# Instalar a AWS CLI versão 2 no Linux -> https://docs.aws.amazon.com/pt_br/cli/latest/userguide/install-cliv2-linux.html
cd /home/ubuntu
apt install -y unzip # p7zip-full
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
rm -rf awscliv2.zip
sudo ./aws/install
aws --version

## OK!!!!!!!

echo "#2 - Web server and dependencies setup"

# Set web server (apache)
PUBHOST=$(ec2metadata --public-hostname | cut -d : -f 2 | tr -d " ")

# Install web server
apt install -y apache2

systemctl restart apache2
systemctl status apache2

a2enmod ssl rewrite headers deflate socache_shmcb # ????

systemctl restart apache2
systemctl status apache2

#Create directory structure
mkdir -p /var/www/canvas/html
chown -R www-data:www-data /var/www/canvas/html
chown -R www-data:www-data /mnt/canvas/bkp/{db,data,html,auto} # Creates backup folders

# Create new conf files
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/canvas.conf
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/canvas-ssl.conf

# Gets public hostname
PUBHOST=$(ec2metadata --public-hostname | cut -d : -f 2 | tr -d " ")
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt -subj $"/C=BR/ST=PR/L=CWB/O=MDLTEST/CN='${PUBHOST}$'"

# Set webmaster email
if [[ -z "${ADM_EMAIL}" ]]; then # If variable is defined
  sed -i 's/webmaster@localhost/admin@fake.mail/' /etc/apache2/sites-available/canvas-ssl.conf
  sed -i 's/webmaster@localhost/admin@fake.mail/' /etc/apache2/sites-available/canvas.conf
else
  sed -i 's/webmaster@localhost/'"$ADM_EMAIL"'/' /etc/apache2/sites-available/canvas-ssl.conf
  sed -i 's/webmaster@localhost/'"$ADM_EMAIL"'/' /etc/apache2/sites-available/canvas.conf
fi

sed -i 's/\/var\/www\/html/\/var\/www\/canvas\/html/' /etc/apache2/sites-available/canvas-ssl.conf
sed -i 's/\/var\/www\/html/\/var\/www\/canvas\/html/' /etc/apache2/sites-available/canvas.conf
sed -i 's/ssl-cert-snakeoil.pem/apache-selfsigned.crt/' /etc/apache2/sites-available/canvas-ssl.conf
sed -i 's/ssl-cert-snakeoil.key/apache-selfsigned.key/' /etc/apache2/sites-available/canvas-ssl.conf

# Redirect http to https
sed -i '/combined/a \\n\tRewriteEngine On \n\tRewriteCond %{HTTPS} off \n\tRewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}' /etc/apache2/sites-available/canvas.conf


a2ensite canvas.conf canvas-ssl.conf # Enable sites
a2dissite 000-default.conf default-ssl.conf # Disable sites
systemctl reload apache2

echo ""
echo "##---------------------- GENERATES NEW DB -------------------------##"
echo ""

# Install db 
apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql

mkdir -p /mnt/canvas/db/data
chown -R postgres:postgres /mnt/canvas/db
sudo -i -u postgres /usr/lib/postgresql/12/bin/pg_ctl -D /mnt/canvas/db/data initdb # Inits database
systemctl start postgresql
psql --version

echo "Install pwgen..."
# https://www.2daygeek.com/5-ways-to-generate-a-random-strong-password-in-linux-terminal/
apt install -y pwgen # Install pwgen


PGDBNAME=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon db name
PGDBUSER=$(pwgen -s 10 -1 -v -A -0) # Generates ramdon user name
PGDBPASS=$(pwgen -s 14 1) # Generates ramdon password for db user
echo "DB Name: $PGDBNAME"
echo "DB User: $PGDBUSER"
echo "DB Pass: $PGDBPASS"
echo ""

touch /tmp/createdbuser.sql
echo $'CREATE DATABASE '${PGDBNAME}$';' >> /tmp/createdbuser.sql
echo $'CREATE USER '${PGDBUSER}$' WITH PASSWORD \''${PGDBPASS}$'\';' >> /tmp/createdbuser.sql
echo $'GRANT ALL PRIVILEGES ON DATABASE '${PGDBNAME}$' TO '${PGDBUSER}$';' >> /tmp/createdbuser.sql
cat /tmp/createdbuser.sql
echo ""

sudo -i -u postgres psql -f /tmp/createdbuser.sql
# rm /tmp/createdbuser.sql


# https://github.com/instructure/canvas-lms/wiki/Production-Start


# Install dependencies
# https://www.howtoforge.com/tutorial/ubuntu-ruby-on-rails/
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
rvm get stable --autolibs=enable
usermod -a -G rvm root
rvm version

rvm install ruby-2.7.1
rvm --default use ruby-2.7.1

ruby -v

# Install Nodejs and Yarn
apt install -y gcc g++ make
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

apt update && apt install -y yarn nodejs

echo "Check the Nodejs version:"
node --version
echo "Check the Yarn package manager version:"
yarn --version

gem update --system
echo "gem: --no-document" >> ~/.gemrc
echo "Check the gem version:"
gem -v

# Install Ruby on Rails  - Precisa ser instalado?
gem install rails
rails --version

apt install -y zlib1g-dev libxml2-dev libsqlite3-dev libpq-dev libxmlsec1-dev python

# Clone repo
cd /var/www/canvas
git clone --depth=1 --branch=stable https://github.com/instructure/canvas-lms.git core

# Configure canvas
cd /var/www/canvas/core
for config in amazon_s3 database \
  delayed_jobs domain file_store outgoing_mail security external_migration; \
  do cp config/$config.yml.example config/$config.yml; done
  
cp config/dynamic_settings.yml.example config/dynamic_settings.yml
# config/dynamic_settings.yml

# Database configuration
cp config/database.yml.example config/database.yml
# nano config/database.yml
sed -i 's/canvas_production/'"$PGDBNAME"'/' config/database.yml # OK!
sed -i 's/your_password/'"$PGDBPASS"'/' config/database.yml # OK!
sed -i 's/canvas/'"$PGDBUSER"'/' config/database.yml # OK!


# Outgoing mail configuration
cp config/outgoing_mail.yml.example config/outgoing_mail.yml
# config/outgoing_mail.yml
# Set webmaster email
if [[ -z "${SMTP_HOST}" ]]; then # If variable is not defined
   echo "Outgoing mail not configured!"
else
  sed -i 's/smtp.example.com/'"$SMTP_HOST"'/' config/outgoing_mail.yml # OK!
  sed -i 's/canvas@example.com/'"$ADM_EMAIL"'/' config/outgoing_mail.yml # OK!
  sed -i 's/user_name: "user"/user_name: "'"$SMTP_USER"'"/' config/outgoing_mail.yml # OK!
  sed -i 's/password: "password"/password: "'"$SMTP_PASS"'"/' config/outgoing_mail.yml # OK!
  sed -i 's/authentication: "plain"/authentication: "login"/' config/outgoing_mail.yml # OK!
  sed -i 's/port: "25"/port: "587"/' config/outgoing_mail.yml # OK!
  SMTP_DOMAIN=$(echo $SMTP_USER | cut -d @ -f2)
  sed -i 's/domain: "example.com"/domain: "'"$SMTP_DOMAIN"'"/' config/outgoing_mail.yml # OK!
fi

# URL configuration
cp config/domain.yml.example config/domain.yml
# nano config/domain.yml
sed -i 's/canvas.example.com/'"$PUBHOST"'/' config/domain.yml # OK!

# Security configuration
cp config/security.yml.example config/security.yml
# nano config/security.yml
# KEY=$(date | md5sum | cut -d - -f1)
KEY=$(date | sha256sum | cut -d - -f1)
# echo $KEY
sed -i 's/12345/'"$KEY"'/' config/security.yml # OK!

# Generate Assets

mkdir -p log tmp/pids public/assets app/stylesheets/brandable_css_brands
touch app/stylesheets/_brandable_variables_defaults_autogenerated.scss
touch Gemfile.lock
touch log/production.log

sudo adduser --disabled-password --gecos canvas canvasuser

sudo chown -R canvasuser config/environment.rb log tmp public/assets \
app/stylesheets/_brandable_variables_defaults_autogenerated.scss \
app/stylesheets/brandable_css_brands Gemfile.lock config.ru

yarn install # Error here!!!

RAILS_ENV=production bundle exec rake canvas:compile_assets

