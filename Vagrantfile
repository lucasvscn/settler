VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	# Configure The Box
	config.vm.box = "centos/7"
	config.vm.hostname = "settler"

	# Don't Replace The Default Key https://github.com/mitchellh/vagrant/pull/4707
	config.ssh.insert_key = false

	config.vm.provider "virtualbox" do |vb|
		vb.customize ["modifyvm", :id, "--memory", "1024"]
		vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
		vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
	end

	config.vm.synced_folder './', '/vagrant', disabled: true

	# Run The Base Provisioning Script
	config.vm.provision 'shell', path: './scripts/provision.sh'
end
