#!/bin/bash

# This is where the variables for the rest of the installation are created
USER=vagrant
DBROOTPASSWORD=qwerty
DBNAME=wordpress
DBUSER=wordpressuser
DBPASSWORD=password
DBPREFIX=wnotp_
SITENAME=sureshjoshi.com

echo "*******************************" 
echo "Provisioning virtual machine..."
echo "*******************************" 


echo "***********************"
echo "Updating apt sources..."
echo "***********************"
sudo apt-get update -qq > /dev/null
sudo apt-get dist-upgrade -qq > /dev/null


echo "********************************"
echo "Installing and securing MariaDB..."
echo "********************************"

echo "mysql-server mysql-server/root_password password $DBROOTPASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DBROOTPASSWORD" | debconf-set-selections
sudo apt-get install -qq mariadb-server > /dev/null
sudo mysql_install_db
# Emulate results of mysql_secure_installation, without using 'expect' to handle input
mysql --user=root --password=$DBROOTPASSWORD -e "UPDATE mysql.user SET Password=PASSWORD('$DBROOTPASSWORD') WHERE User='root'"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.user WHERE User=''"
mysql --user=root --password=$DBROOTPASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql --user=root --password=$DBROOTPASSWORD -e "FLUSH PRIVILEGES"


echo "********************************************************"
echo "Installing PHP and disabling path info default settings..."
echo "********************************************************"
sudo apt-get install -qq php5-fpm php5-mysql php5-gd libssh2-php > /dev/null
sudo cp /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.orig
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php5/fpm/php.ini
sudo service php5-fpm restart


echo "***********************************************"
echo "Installing NGinx and removing default config..."
echo "***********************************************"
sudo apt-get install -qq nginx > /dev/null

# If you want to test your Nginx-PHP config, uncomment the lines below, but be SURE to delete the .php file after testing
# sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.orig
# sudo cp /vagrant/provision/nginx.php /etc/nginx/sites-available/default
# sudo service nginx reload
# sudo cp /vagrant/provision/info.php /usr/share/nginx/html/info.php

# Remove the default nginx config from sites-enabled
sudo rm /etc/nginx/sites-enabled/default


echo "*********************************"
echo "Setting up NGinx for Wordpress..."
echo "*********************************"
sudo cp /vagrant/provision/nginx/common /etc/nginx -r
sudo cp /vagrant/provision/nginx/wptemplate.nginx /etc/nginx/sites-available/$SITENAME
sed -i "s/SITENAME/$SITENAME/g" /etc/nginx/sites-available/$SITENAME
sudo ln -s /etc/nginx/sites-available/$SITENAME /etc/nginx/sites-enabled/
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
sudo cp /vagrant/provision/nginx/nginx.conf /etc/nginx/
sudo service nginx reload
sudo service php5-fpm restart


echo "************************************"
echo "Setting up database for Wordpress..."
echo "************************************"
mysql --user=root --password=$DBROOTPASSWORD -e "CREATE DATABASE $DBNAME;"
mysql --user=root --password=$DBROOTPASSWORD -e "CREATE USER $DBUSER@localhost IDENTIFIED BY '$DBPASSWORD';"
mysql --user=root --password=$DBROOTPASSWORD -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER@localhost;"
mysql --user=root --password=$DBROOTPASSWORD -e "FLUSH PRIVILEGES;"


echo "********************************"
echo "Transferring Duplicator files..."
echo "********************************"
SITEPATH=/var/www/$SITENAME
sudo mkdir -p $SITEPATH/html
sudo cp /vagrant/provision/duplicator/* $SITEPATH/html/
sudo chown -R $USER:www-data $SITEPATH/*

# Setup file and directory for Duplicator - CHANGE 0775 back to 0755 after Duplicator is finished
sudo find $SITEPATH/html -type d -exec chmod 0775 {} \;
sudo find $SITEPATH/html -type f -exec chmod 0644 {} \;

# Should run these commands after Duplicator is finished
# sudo chown -R $USER:$USER $SITEPATH/*
# sudo chown -R $USER:www-data $SITEPATH/html/wp-content
echo "**************************************************************"
echo "Success! Navigate to your website's URL to finish the setup..."
echo "**************************************************************"
