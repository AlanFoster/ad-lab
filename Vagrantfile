# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'ostruct'
require 'json'

# Simple helper to allow dotted access to a hash value, i.e. using {a.b.c} instead of {a[:b][:c]}
def as_open_struct(value)
  JSON.parse(value.to_json, object_class: OpenStruct)
end

machines = as_open_struct({
  'dc01' => {
    name: 'DC01',
    hostname: 'DC01',
    ip: '10.10.10.5',
    netmask: '255.255.0.0',
    box: 'StefanScherer/windows_2016',
    box_version: '2019.02.14',
    # box: 'gusztavvargadr/windows-server',
    # box_version: '2102.0.2303',
    admin_password: 'dc01vagrant',
    type: 'domain',
    domain: 'demo.local'
  },

  'ws01' => {
    name: 'WS01',
    hostname: 'WS01',
    ip: '10.10.10.6',
    netmask: '255.255.0.0',
    box: 'StefanScherer/windows_2016',
    box_version: '2019.02.14',
    admin_password: 'ws01vagrant',
    type: 'workstation',
    domain: 'demo.local',
    domain_ip: '10.10.10.5',
    domain_admin_password: 'dc01vagrant'
  },

  'dc02' => {
    name: 'DC02',
    hostname: 'DC02',
    ip: '10.10.11.5',
    netmask: '255.255.0.0',
    box: 'StefanScherer/windows_2016',
    box_version: '2019.02.14',
    admin_password: 'dc02vagrant',
    type: 'child_domain',
    domain: 'dev.demo.local',
    domain_ip: '10.10.11.6',
    parent_domain: 'demo.local',
    parent_domain_ip: '10.10.10.5',
    parent_domain_admin_password: 'dc01vagrant',
  },
  'kali' => {
    name: 'Kali',
    hostname: 'Kali',
    ip: '10.10.10.10',
    netmask: '255.255.0.0',
    box: 'kalilinux/rolling',
    box_version: '2023.1.0',
    admin_password: 'vagrant',
  },
  'windev' => {
    name: 'WinDev',
    hostname: 'WinDev',
    ip: '10.10.10.11',
    netmask: '255.255.0.0',
    box: 'StefanScherer/windows_2016',
    box_version: '2019.02.14',
    # box: 'StefanScherer/windows_10',
    # box_version: '2021.12.09',
    # box: 'gusztavvargadr/windows-10',
    # box_version: '2202.0.2303',
    admin_password: 'vagrant',
  }
})

# Register Choco software provisioning scripts for the given vm_config
def with_common_software(vm_config)
  vm_config.vm.provision("shell", path: "scripts/windows/software-01-install-choco.ps1")
  vm_config.vm.provision("shell", reboot: true)
  vm_config.vm.provision("shell", path: "scripts/windows/software-02-common.ps1")
  vm_config.vm.provision("shell", reboot: true)
end

Vagrant.configure("2") do |config|
  # Disable vagrant-vbguest for faster setup times
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
    config.vbguest.no_remote = true
  end

  config.vm.define("DC01", autostart: false) do |vm_config|
    vm_config.vm.box = machines.dc01.box
    vm_config.vm.box_version = machines.dc01.box_version
    vm_config.vm.hostname = machines.dc01.hostname

    # Communication configuration
    vm_config.winrm.retry_limit = 60
    vm_config.winrm.retry_delay = 10

    # Use WinRM transport and force plaintext/basic auth - which stops digest initialization errors appearing
    # The docu/mentation has the caveat: Credentials will be transferred in plain text - which is fine for a test lab
    vm_config.winrm.transport = "plaintext"
    vm_config.winrm.basic_auth_only = true

    # IP Accessible from the host machine
    vm_config.vm.network "private_network", ip: machines.dc01.ip, netmask: machines.dc01.netmask

    vm_config.vm.provision(
      "shell",
      path: "scripts/windows/dc01-01-install-forest.ps1",
      args: "-hostname #{machines.dc01.hostname} -domain #{machines.dc01.domain} -domainIp #{machines.dc01.ip} -administratorPassword #{machines.dc01.admin_password}"
    )
    vm_config.vm.provision "shell", reboot: true

    vm_config.vm.provision(
      "shell",
      path: "scripts/windows/dc01-02-configure-dns.ps1",
      args: "-hostname #{machines.dc01.hostname} -domain #{machines.dc01.domain} -domainIp #{machines.dc01.ip} -administratorPassword #{machines.dc01.admin_password}"
    )

    vm_config.vm.provision(
      "shell",
      path: "scripts/windows/dc01-03-create-ad-objects.ps1",
      args: "-hostname #{machines.dc01.hostname} -domain #{machines.dc01.domain} -domainIp #{machines.dc01.ip} -administratorPassword #{machines.dc01.admin_password}"
    )

    if ENV['INSTALL_SOFTWARE']
      with_common_software(vm_config)
    end
  end

  config.vm.define("WS01", autostart: false) do |vm_config|
    vm_config.vm.box = machines.ws01.box
    vm_config.vm.box_version = machines.ws01.box_version
    vm_config.vm.hostname = machines.ws01.hostname

    # Communication configuration
    vm_config.winrm.retry_limit = 60
    vm_config.winrm.retry_delay = 10

    # Use WinRM transport and force plaintext/basic auth - which stops digest initialization errors appearing
    # The documentation has the caveat: Credentials will be transferred in plain text - which is fine for a test lab
    vm_config.winrm.transport = "plaintext"
    vm_config.winrm.basic_auth_only = true

    # IP Accessible from the host machine
    vm_config.vm.network "private_network", ip: machines.ws01.ip, netmask: machines.ws01.netmask

    vm_config.vm.provision(
      "shell",
      path: "scripts/windows/ws01-01-install-workstation.ps1",
      args: "-domain #{machines.ws01.domain} -domainIp #{machines.ws01.domain_ip} -domainAdministratorPassword #{machines.ws01.domain_admin_password} -administratorPassword #{machines.ws01.admin_password}"
    )
    vm_config.vm.provision "shell", reboot: true
    if ENV['INSTALL_SOFTWARE']
      with_common_software(vm_config)
    end
  end

  config.vm.define("DC02", autostart: false) do |vm_config|
    vm_config.vm.box = machines.dc02.box
    vm_config.vm.box_version = machines.dc02.box_version
    vm_config.vm.hostname = machines.dc02.hostname

    # Communication configuration
    vm_config.winrm.retry_limit = 60
    vm_config.winrm.retry_delay = 10

    # Use WinRM transport and force plaintext/basic auth - which stops digest initialization errors appearing
    # The documentation has the caveat: Credentials will be transferred in plain text - which is fine for a test lab
    vm_config.winrm.transport = "plaintext"
    vm_config.winrm.basic_auth_only = true

    # IP Accessible from the host machine
    vm_config.vm.network "private_network", ip: machines.dc02.ip, netmask: machines.dc02.netmask

    vm_config.vm.provision(
      "shell",
      path: "scripts/windows/dc02-01-install-forest.ps1",
      args: "-parentDomain #{machines.dc02.parent_domain} -parentDomainIp #{machines.dc02.parent_domain_ip} -domain #{machines.dc02.domain} -domainIp #{machines.dc02.domain_ip} -parentDomainAdministratorPassword #{machines.dc02.parent_domain_admin_password} -administratorPassword #{machines.dc02.admin_password}"
    )
    vm_config.vm.provision "shell", reboot: true
    if ENV['INSTALL_SOFTWARE']
      with_common_software(vm_config)
    end
  end

  config.vm.define("Kali", autostart: false) do |vm_config|
    vm_config.vm.box = machines.kali.box
    vm_config.vm.box_version = machines.kali.box_version
    vm_config.vm.hostname = machines.kali.hostname

    # IP Accessible from the host machine
    vm_config.vm.network "private_network", ip: machines.kali.ip, netmask: machines.kali.netmask
  end

  config.vm.define("WinDev", autostart: false) do |vm_config|
    vm_config.vm.box = machines.windev.box
    vm_config.vm.box_version = machines.windev.box_version
    vm_config.vm.hostname = machines.windev.hostname

    # IP Accessible from the host machine
    vm_config.vm.network "private_network", ip: machines.windev.ip, netmask: machines.windev.netmask

    vm_config.vm.provision("shell", path: "scripts/windows/ConfigureRemotingForAnsible.ps1")
    vm_config.vm.provision("shell", path: "scripts/windows/install-choco.ps1")
    # XXX: vmware requires an additional configuration step:
    # ==> WinDev: Configuring secondary network adapters through VMware
    # ==> WinDev: on Windows is not yet supported. You will need to manually
    # ==> WinDev: configure the network adapter.
    # https://github.com/hashicorp/vagrant/issues/5000
  end

  config.vm.provider "vmware_desktop" do |v|
    v.gui = true
    v.linked_clone = false
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = "2"
  end

  config.vm.provider "virtualbox" do |virtualbox|
    # Display the VirtualBox GUI when booting the machine
    virtualbox.gui = true

    # You can create a full copy or a linked copy of an existing VM; Linked clones are faster
    # https://github.com/hashicorp/vagrant/blob/2a22359380738ebc3eed2e4a76c6da966ffed19b/website/content/docs/providers/virtualbox/configuration.mdx#linked-clones
    virtualbox.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')

    # By default Vagrant will check for the VirtualBox Guest Additions when starting a machine; skip it
    # https://github.com/hashicorp/vagrant/blob/2a22359380738ebc3eed2e4a76c6da966ffed19b/website/content/docs/providers/virtualbox/configuration.mdx#checking-for-guest-additions
    virtualbox.check_guest_additions = false

    # Customize memory and CPUs for faster boot/provisioning time
    virtualbox.customize [
      "modifyvm", :id,
      "--memory", "4096",
      "--cpus", "2",
      "--ioapic", "on",
      '--clipboard-mode', 'bidirectional',
      '--draganddrop', 'bidirectional'
    ]
  end
end
