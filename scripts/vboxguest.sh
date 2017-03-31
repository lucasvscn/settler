#!/usr/bin/env bash

vboxga_version='5.1.10'
isofile="VBoxGuestAdditions_$vboxga_version.iso"
url="http://download.virtualbox.org/virtualbox/$vboxga_version/$isofile"
curl -L -o /home/vagrant/$isofile $url

mount -o loop /home/vagrant/$isofile /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
rm -rf /home/vagrant/$isofile
