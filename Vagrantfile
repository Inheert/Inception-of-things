Vagrant.configure(2) do |config|
	vm_name = "ProjectVM"

	config.vm.box = "generic/debian12"

	config.vm.define vm_name do |control|
		control.vm.hostname = vm_name

		control.vm.network "private_network", ip: "192.168.57.100"

		control.vm.synced_folder ".", "/home/vagrant/inception-of-things"

		control.vm.provider "virtualbox" do |v|
			v.name = vm_name
			v.memory = 8192
			v.cpus = 6
			v.customize ["modifyvm", :id, "--cpuexecutioncap", "80", "--nested-hw-virt", "on"]
		end

		control.vm.provision "shell", path: "./scripts/setup.sh"
	end
end
