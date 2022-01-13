#!/bin/bash

## Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


## put value for mysql root password 
wordpressDbName='wp_db'
DbRootPass='password'


## Update system
echo "Update System"
apt-get update -y

## Install APache
echo "Install Apache."
sudo apt-get install apache2 apache2-utils -y
systemctl start apache2
systemctl enable apache2

## Install PHP
echo "Install PHP."
apt-get install php libapache2-mod-php php-mysql -y

# Install MySQL database server
echo "Install MySQL database server"
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DbRootPass"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DbRootPass"
apt-get install mysql-server mysql-client -y

## Install Latest WordPress
echo 'Install Latest WordPress.'
rm /var/www/html/index.*
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
rsync -av wordpress/* /var/www/html/

## Set Permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

## Configure WordPress Database
mysql -u root -p$DbRootPass <<QUERY_INPUT
CREATE DATABASE $wordpressDbName;
GRANT ALL PRIVILEGES ON $wordpressDbName.* TO 'root'@'localhost' IDENTIFIED BY '$DbRootPass';
FLUSH PRIVILEGES;
EXIT
QUERY_INPUT

## Add Database Credentias in wordpress
cd /var/www/html/
sudo mv wp-config-sample.php wp-config.php
perl -pi -e "s/database_name_here/$wordpressDbName/g" wp-config.php
perl -pi -e "s/username_here/root/g" wp-config.php
perl -pi -e "s/password_here/$DbRootPass/g" wp-config.php

## Enabling Mod Rewrite
a2enmod rewrite  

## we can also add phpmyadmin to work with database in web application
## Install PhpMyAdmin

echo 'Get PhpMyAdmin  '
apt-get install phpmyadmin -y

## Configure PhpMyAdmin
echo 'Include /etc/phpmyadmin/apache.conf' >> /etc/apache2/apache2.conf

## Restart Apache and Mysql
service apache2 restart
service mysql restart

echo '#########################'
echo "Installation is complete."
echo "-------------------------"