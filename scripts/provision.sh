#!/bin/bash

# Install extra repositories

yum -y install epel-release
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

yum -y install https://centos7.iuscommunity.org/ius-release.rpm
rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

# Install dev & utils

yum -y install bash-completion git vim curl htop unzip rar \
sqlite dos2unix gcc make python-pip poppler-utils man \
kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms

# Set my timezone

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Apache 2.4

yum -y install httpd httpd-tools

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

# MySQL 5.7

# rpm -ivh https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
# yum -y install mysql-server

# systemctl enable mysqld
# systemctl start mysqld

# password=`grep 'temporary password' /var/log/mysqld.log | sed -e 's/^.*root@localhost: //'`
# mysql --user="root" --password="$password" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'secret';"
# mysql --user="root" --password="secret" -e "CREATE USER 'root'@'0.0.0.0' IDENTIFIED BY 'secret';"
# mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
# mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'root'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
# mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
# mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"

# systemctl restart mysqld

# Caching & Queues

yum -y install libmemcached libmemcached-devel memcached beanstalkd

# Cleaning up

yum clean all

dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
