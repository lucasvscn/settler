#!/usr/bin/env bash

# Install extra repositories

yum -y install epel-release
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

yum -y install https://centos7.iuscommunity.org/ius-release.rpm
rpm --import /etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY

# Install dev & utils

yum -y install bash-completion git vim wget curl htop unzip rar \
sqlite dos2unix gcc make python-pip poppler-utils man net-tools \
kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms

# Upgrade

yum -y upgrade

yum -y install dkms

yum -y groupinstall "Development Tools"

yum -y install kernel-devel

# SELinux Disabled
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/sysconfig/selinux
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
