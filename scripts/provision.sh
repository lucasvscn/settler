#!/usr/bin/env bash

# Upgrade Packages

yum check-update

yum -y upgrade

# Install Extra Packages

# RPMforge
rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

# EPEL
rpm --import https://fedoraproject.org/static/0608B895.txt
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# Remi
rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
rpm -Uvh http://rpms.famillecollet.com/enterprise/6/remi/x86_64/remi-release-6.5-1.el6.remi.noarch.rpm

# Enable C6.5-centosplus repository
repo="/etc/yum.repos.d/CentOS-Vault.repo"
n=$(grep -n "enabled=0" $repo | grep -Eo '^[^:]+' | tac | sed q)
sed "$((n))s/enabled=0/enabled=1/" $repo


# Utilities
yum -y install bash-completion git gitflow \
vim curl wget lynx mc htop unzip rar ctags \
sqlite realpath zsh dos2unix whois re2c \
gcc make python-pip poppler-utils man \
kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms

# Updates VirtualBox Guess Aditions
vboxga_version=$(VBoxControl --version | grep -o '[0-9\.]\+' | head -n1)
isofile="VBoxGuestAdditions_$vboxga_version.iso"
url="http://download.virtualbox.org/virtualbox/$vboxga_version/$isofile"
curl -L -o /home/vagrant/$isofile $url

mount -o loop /home/vagrant/$isofile /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/vagrant/$isofile

# Allows httpd to access folders within home directory
chmod 755 /home/vagrant/

# Setup .bashrc
cat << EOT > /home/vagrant/.bashrc
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# Enable bash_completion
if [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
fi

# Aditional aliases
if [ -f ~/.bash_aliases ]; then
        . ~/.bash_aliases
fi

# Git
alias g='git'
complete -o default -o nospace -F _git g
EOT


# httpd web server

yum -y install httpd httpd-tools

# Disable 'Welcome' page
sed -i -e '/LocationMatch/,+3 s/^/#/' /etc/httpd/conf.d/welcome.conf
sed -i -r 's/#NameVirtualHost/NameVirtualHost/g' /etc/httpd/conf/httpd.conf

# Disabling 'sendfile' due to VirtualBox bug
# https://github.com/mitchellh/vagrant/issues/351#issuecomment-1339640
sed -i -r 's/#EnableSendfile/EnableSendfile/g' /etc/httpd/conf/httpd.conf

# Setup default VirtualHost
echo "<VirtualHost *:80>
  ServerName localhost
</VirtualHost>" | tee /etc/httpd/conf.d/0Default.conf

# Firewall settings
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
service iptables save

# Enabling service
chkconfig httpd on
service httpd start

# Install Node

yum -y install nodejs npm
sudo su vagrant <<'EOF'
/usr/bin/npm install -g grunt-cli
/usr/bin/npm install -g gulp
/usr/bin/npm install -g bower
EOF
rm -rf /home/vagrant/{tmp,npm-*.log}


# Install PHP

yum -y --enablerepo=remi,remi-php54 install php php-cli php-pdo php-mysqlnd \
php-pgsql php-pecl-sqlite php-pecl-mongo php-redis php-gd \
php-xml php-mcrypt php-mbstring php-pecl-apcu php-bcmath \
php-pecl-memcache php-pecl-memcached php-pecl-xdebug php-imap php-gmp \
php-pecl-mailparse

echo "<?php phpinfo();" | tee /var/www/html/info.php


# Configure PHP options
declare -A PHP_SETTINGS
PHP_SETTINGS[allow_call_time_pass_reference]=Off
PHP_SETTINGS[display_errors]=On
PHP_SETTINGS[display_startup_errors]=On
PHP_SETTINGS[error_reporting]="E_ALL"
PHP_SETTINGS[html_errors]=On
PHP_SETTINGS[log_errors]=On
PHP_SETTINGS[magic_quotes_gpc]=Off
PHP_SETTINGS[max_input_time]=60
PHP_SETTINGS[output_buffering]=4096
PHP_SETTINGS[register_argc_argv]=Off
PHP_SETTINGS[register_long_arrays]=Off
PHP_SETTINGS[request_order]="GP"
PHP_SETTINGS[session.bug_compat_42]=Off
PHP_SETTINGS[session.bug_compat_warn]=Off
PHP_SETTINGS[session.gc_divisor]=1000
PHP_SETTINGS[session.hash_bits_per_character]=5
PHP_SETTINGS[short_open_tag]=Off
PHP_SETTINGS[track_errors]=On
PHP_SETTINGS[upload_max_filesize]=32M
PHP_SETTINGS[post_max_size]=32M

for i in "${!PHP_SETTINGS[@]}"
do
    sed -ri "s/$i = .*/$i = ${PHP_SETTINGS[$i]}/g" /etc/php.ini
done

# timezone settings
sed -ri 's/;date.timezone =/date.timezone = UTC/g' /etc/php.ini

echo "xdebug.remote_enable = 1" >> /etc/php.d/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php.d/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php.d/xdebug.ini

# Install Composer

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path

printf "\nPATH=\"/home/vagrant/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.bash_profile

# Install Laravel Envoy and PHP CS Fixer

sudo su vagrant <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
/usr/local/bin/composer global require "laravel/installer=~1.0"
/usr/local/bin/composer global require "fabpot/php-cs-fixer=~1.4"
EOF


# Install phpMyAdmin

yum -y --enablerepo=remi,remi-php54 install phpMyAdmin

sed -i 11,39d /etc/httpd/conf.d/phpMyAdmin.conf
sed -i "s/AllowNoPassword'] = false;/AllowNoPassword'] = true;/g" /etc/phpMyAdmin/config.inc.php


# Install MySQL

yum -y --enablerepo=remi,remi-php54 install mysql mysql-server

chkconfig mysqld on
service mysqld start

# Configure MySQL Remote Access

mysql --user="root" -e "GRANT ALL ON *.* TO root@'10.0.2.2' WITH GRANT OPTION;"
service mysql restart

mysql --user="root" -e "CREATE USER 'workstead'@'10.0.2.2' IDENTIFIED BY 'secret';"
mysql --user="root" -e "GRANT ALL ON *.* TO 'workstead'@'10.0.2.2' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "GRANT ALL ON *.* TO 'workstead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "GRANT ALL ON *.* TO 'workstead'@'localhost' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" -e "FLUSH PRIVILEGES;"
mysql --user="root" -e "CREATE DATABASE workstead;"
service mysql restart

iptables -I INPUT -p tcp --dport 3306 -j ACCEPT
service iptables save


# Install A Few Other Things

yum -y install libmemcached libmemcached-devel memcached redis beanstalkd
chkconfig memcached on
chkconfig redis on
chkconfig beanstalkd on

