#!/usr/bin/env bash

yum clean all

yum -y install epel-release

rpm -Uvh https://centos7.iuscommunity.org/ius-release.rpm


yum -y install bash-completion git vim curl htop unzip rar \
sqlite dos2unix gcc make python-pip poppler-utils man \
kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms

# Install VirtualBox Guess Aditions
vboxga_version='5.0.14'
isofile="VBoxGuestAdditions_$vboxga_version.iso"
url="http://download.virtualbox.org/virtualbox/$vboxga_version/$isofile"
curl -L -o /home/vagrant/$isofile $url

mount -o loop /home/vagrant/$isofile /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/vagrant/$isofile

# Set My Timezone

ln -sf /usr/share/zoneinfo/America/Recife /etc/localtime


chmod 755 /home/vagrant/

curl -o /usr/local/etc/git_prompt https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

cat << EOT >> /home/vagrant/.bashrc

# Enable bash_completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# Enable bash_completion
if [ -f /usr/local/etc/git_prompt ]; then
    . /usr/local/etc/git_prompt
fi

# Git
alias g='git'
complete -o default -o nospace -F _git g

# prompt displays current branch
PS1=\$PS1'\\[\\e[33m\\]\$(__git_ps1 "(%s) ")\\[\\e[0m\\]'
EOT


# Apache

yum -y install httpd httpd-tools

# disable 'welcome' page
sed -i -e '/LocationMatch/,+14 s/^/#/' /etc/httpd/conf.d/welcome.conf

# https://github.com/mitchellh/vagrant/issues/351#issuecomment-1339640
sed -i -r 's/#EnableSendfile/EnableSendfile/g' /etc/httpd/conf/httpd.conf

# Install NodeJS

curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs

npm install -g grunt-cli
npm install -g gulp
npm install -g bower

# Install PHP

yum -y install php56u php56u-pdo php56u-mssql php56u-mbstring \
php67u-ldap php56u-mcrypt php56u-pecl-apcu php56u-pecl-memcache \
php56u-pecl-memcached php56u-pecl-xdebug php56u-bcmath

# Install Composer

curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path

printf "\nPATH=\"$(sudo su - vagrant -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.bashrc

# Install Laravel Envoy & Installer

sudo su vagrant <<'EOF'
/usr/local/bin/composer global require "laravel/envoy=~1.0"
/usr/local/bin/composer global require "laravel/installer=~1.1"
EOF

# Set Some PHP CLI Settings

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php.ini
sed -i "s/;date.timezone.*/date.timezone = America\/Recife/" /etc/php.ini


echo "xdebug.remote_enable = 1" >> /etc/php.d/20-xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php.d/20-xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php.d/20-xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php.d/20-xdebug.ini

echo "<?php phpinfo();" | tee /var/www/html/info.php

yum -y install libmemcached libmemcached-devel memcached beanstalkd


# Install Supervisord

easy_install supervisord
echo_supervisord_conf > /etc/supervisord.conf
curl -o /etc/systemd/system/supervisord.service https://raw.githubusercontent.com/Supervisor/initscripts/master/centos-systemd-etcs


# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
