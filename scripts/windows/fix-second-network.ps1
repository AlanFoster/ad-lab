# VMWare doesn't appear to config the second network adapter correctly; This is therefore set manually:
# https://github.com/hashicorp/vagrant/issues/5000#issuecomment-258209286

# Ethernet0 is the default adapter used for NAT; Ethernet1 is the custom adapter configured within Vagrantfile

param (
    [parameter(Mandatory=$true)]
    [String] $ip,

    [parameter(Mandatory=$true)]
    [String] $netmask
)

netsh.exe int ip set address Ethernet1 static $ip $netmask
