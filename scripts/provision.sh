#!/usr/bin/env bash

# Set my timezone

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Apache 2.4

yum -y install httpd httpd-tools

mkdir /etc/httpd/ssl

echo "<VirtualHost *:80>
    ServerName localhost
    DocumentRoot "/var/www/html"

    <Directory "/var/www/html">
        AllowOverride all
    </Directory>
</VirtualHost>" | tee /etc/httpd/conf.d/0Default.conf

echo "<?php phpinfo();" | tee /var/www/html/info.php

sed -i 's/User apache/User vagrant/' /etc/httpd/conf/httpd.conf
sed -i 's/Group apache/Group vagrant/' /etc/httpd/conf/httpd.conf

sed -i 's/^/\#/' /etc/httpd/conf.d/welcome.conf

mkdir -pv /etc/httpd/ssl

systemctl enable httpd
systemctl start httpd

# Install PHP 5.6

yum -y install php56u php56u-bcmath php56u-cli php56u-gd php56u-imap \
php56u-ioncube-loader php56u-ldap php56u-mbstring php56u-mcrypt php56u-mssql \
php56u-mysqlnd php56u-opcache php56u-pdo php56u-pecl-apcu php56u-pecl-geoip \
php56u-pecl-imagick php56u-pecl-memcache php56u-pecl-memcached \
php56u-pecl-xdebug php56u-soap php56u-xml php56u-xmlrpc

# Install Composer

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '669656bab3166a7aff8a7506b8cb2d1c292f042046c5a994c43155c0be6190fa0355160742ab2e1c88d40d5be660b410') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

mv composer.phar /usr/local/bin/composer

# Install Laravel Envoy & Installer

sudo su vagrant <<'EOF'
/usr/local/bin/composer global require "laravel/installer"
EOF

printf "\nPATH=\"$(sudo su - vagrant -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.bashrc

# Set Some PHP CLI Settings

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php.ini
sed -i "s/;date.timezone.*/date.timezone = America\/Sao_Paulo/" /etc/php.ini

echo "xdebug.remote_enable = 1" >> /etc/php.d/20-xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php.d/20-xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php.d/20-xdebug.ini

echo "<?php phpinfo();" | tee /var/www/html/info.php

# MySQL 5.6

rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm

yum-config-manager --disable mysql57-community
yum-config-manager --enable mysql56-community

yum -y install mysql-community-server

systemctl enable mysqld
systemctl restart mysqld

mysql --user="root" -e "CREATE USER 'root'@'0.0.0.0' IDENTIFIED BY 'secret';"
mysql --user="root" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "GRANT ALL ON *.* TO 'root'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "FLUSH PRIVILEGES;"

# phpMyAdmin

yum -y install phpmyadmin

sed -i '/Require ip/d' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i '/Allow from/d' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i '/RequireAny/d' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i 's/Deny from All/Allow from All/' /etc/httpd/conf.d/phpMyAdmin.conf
sed -i '/# Apache 2.4/a Require all granted' /etc/httpd/conf.d/phpMyAdmin.conf

# Caching & Queues

yum -y install libmemcached libmemcached-devel memcached beanstalkd

systemctl enable memcached
systemctl start memcached

systemctl enable beanstalkd
systemctl start beanstalkd

# # Memcached monitor
# wget https://github.com/elijaa/phpmemcachedadmin/archive/1.3.0.tar.gz
# tar xzf 1.3.0.tar.gz
# mv phpmemcachedadmin-1.3.0 /var/www/html/phpmemcachedadmin
# chmod -R 777 /var/www/html/phpmemcachedadmin/Config
# chmod -R 777 /var/www/html/phpmemcachedadmin/Temp
# rm -f 1.3.0.tar.gz

# # Beanstalkd
# curl -o phpbeanstalkadmin.zip -O https://codeload.github.com/mnapoli/phpBeanstalkdAdmin/zip/1.0.0
# unzip phpbeanstalkadmin.zip
# mv phpBeanstalkdAdmin-1.0.0 /var/www/html/phpbeanstalkdadmin
# rm -rf phpbeanstalkadmin.zip

# # OPcache Monitors
# curl -o /var/www/html/opcache.php -O https://raw.githubusercontent.com/rlerdorf/opcache-status/master/opcache.php
# curl -o /var/www/html/opcache-gui.php -O https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php

# Cleaning up

yum clean all

dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
