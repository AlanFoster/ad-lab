# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.synced_folder "./scripts", "/vagrant_scripts"

    # Disable vagrant-vbguest for faster setup times
    if Vagrant.has_plugin?("vagrant-vbguest")
      config.vbguest.auto_update = false
      config.vbguest.no_remote = true
    end

    config.vm.define "DC01" do |vm_config|
      vm_config.vm.box = "StefanScherer/windows_2016"
      vm_config.vm.box_version = "2019.02.14"
      vm_config.vm.hostname = "DC01"

      # Communication configuration
      vm_config.winrm.retry_limit = 60
      vm_config.winrm.retry_delay = 10

      # Use WinRM transport and force plaintext/basic auth - which stops digest initialization errors appearing
      # The documentation has the caveat: Credentials will be transferred in plain text - which is fine for a test lab
      vm_config.winrm.transport = "plaintext"
      vm_config.winrm.basic_auth_only = true

      # IP Accessible from the host machine
      vm_config.vm.network "private_network", ip: '10.10.10.5'

      vm_config.vm.provision(
        "shell",
        path: "scripts/windows/dc01-01-install-forest.ps1",
        args: "-hostname DC01 -domain demo.local -domainIp 10.10.10.5 -administratorPassword vagrant"
      )
      vm_config.vm.provision "shell", reboot: true

      vm_config.vm.provision(
        "shell",
        path: "scripts/windows/dc01-02-configure-dns.ps1",
        args: "-hostname DC01 -domain demo.local -domainIp 10.10.10.5 -administratorPassword vagrant"
      )

      if ENV['INSTALL_SOFTWARE']
        vm_config.vm.provision("shell", path: "scripts/windows/install-software.ps1")
        vm_config.vm.provision "shell", reboot: true
      end
    end

    config.vm.define "DC02" do |vm_config|
        vm_config.vm.box = "StefanScherer/windows_2016"
        vm_config.vm.box_version = "2019.02.14"
        vm_config.vm.hostname = "DC02"

        # Communication configuration
        vm_config.winrm.retry_limit = 60
        vm_config.winrm.retry_delay = 10

        # Use WinRM transport and force plaintext/basic auth - which stops digest initialization errors appearing
        # The documentation has the caveat: Credentials will be transferred in plain text - which is fine for a test lab
        vm_config.winrm.transport = "plaintext"
        vm_config.winrm.basic_auth_only = true

        # IP Accessible from the host machine
        vm_config.vm.network "private_network", ip: '10.10.10.6'

        vm_config.vm.provision(
          "shell",
          path: "scripts/windows/dc02-01-install-forest.ps1",
          args: "-parentDomain demo.local -parentDomainIp 10.10.10.5 -domain dev.demo.local -domainIp 10.10.10.6 -administratorPassword vagrant"
        )
        vm_config.vm.provision "shell", reboot: true
        if ENV['INSTALL_SOFTWARE']
          vm_config.vm.provision("shell", path: "scripts/windows/install-software.ps1")
          vm_config.vm.provision "shell", reboot: true
        end
    end

    config.vm.provider "virtualbox" do |virtualbox|
      # Display the VirtualBox GUI when booting the machine
      virtualbox.gui = true

      # Customize the amount of memory on the VM:
      virtualbox.memory = "4096"
    end
  end
