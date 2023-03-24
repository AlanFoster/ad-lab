param (
    [parameter(Mandatory=$true)]
    [string]$hostname,

    [parameter(Mandatory=$true)]
    [string]$domain,

    [parameter(Mandatory=$true)]
    [string]$domainIp,

    [parameter(Mandatory=$true)]
    [string]$administratorPassword
)

# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

##################################################################################
# Password policy configuration
##################################################################################

Write-Host -fore green '[*] Running password policy logic'

# Ensure passwords never expire
net accounts /maxpwage:unlimited

# Disable automatic machine account password changes
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetLogon\Parameters' -Name DisablePasswordChange -Value 1

# Allow weak passwords
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
Remove-Item -force c:\secpol.cfg -confirm:$false

##################################################################################
# DNS Configuration
##################################################################################

# Remove unwanted NICS from DNS. Virtualbox adds an additional NAT NIC for 10.0.2.15
# that should be removed from DNS registration
# Implements Step 1 of: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/unwanted-nic-registered-dns-mulithomed-dc#resolution
#     Under Network Connections Properties:
#         On the unwanted NIC TCP/IP Properties, select Advanced > DNS, and then unselect Register this connections Address in DNS.
# Steps 2 and 3 are performed after ADDS is installed and the machine has been rebooted
$adapters = Get-WmiObject "Win32_NetworkAdapterConfiguration where IPEnabled='TRUE'"
$adapters | ForEach-Object {
    $requiresDynamicDNSRegistration = $domainIp -In $_.IPAddress
    Write-Host -fore green "[*] Setting dynamic DNS registration for $($_.IPAddress) to $requiresDynamicDNSRegistration"
    $_.SetDynamicDNSRegistration($requiresDynamicDNSRegistration)
}

#####################################################################################
# Forest installation
#####################################################################################

Write-Host -fore green '[*] Running forest installation'
$administratorPasswordSecure = ConvertTo-SecureString $administratorPassword -AsPlainText -Force

# Set local Administrator account password to stop the error:
#   "The new domain cannot be created DC01: because the local Administrator account password does not meet requirements."
Write-Host -fore green '[*] Setting local administrator password'
Set-LocalUser `
    -Name Administrator `
    -AccountNeverExpires `
    -Password $administratorPasswordSecure `
    -PasswordNeverExpires:$true `
    -UserMayChangePassword:$true

Install-WindowsFeature AD-Domain-Services,DNS,RSAT-AD-AdminCenter,RSAT-ADDS-Tools -IncludeManagementTools -Verbose

#
# Install the Active Directory Domain Services (AD DS) environment
#

# Win32_operatingSystem ProductType
#   Work Station (1)
#   Domain Controller (2)
#   Server (3)
# https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingsystem
$isDomainController = (Get-WmiObject -Class Win32_operatingSystem).ProductType -Eq 2
Write-Host -fore green "[*] IsDomainController=$isDomainController"
if (!$isDomainController) {
    $netbios = $domain.split('.')[0].ToUpperInvariant()
    Write-Host -fore green "[*] Installing ADDS for domain $domain and netbios $netbios"
    Install-ADDSForest `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "Win2012R2" `
        -DomainName $domain `
        -DomainNetbiosName $netbios `
        -ForestMode "Win2012R2" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -SafeModeAdministratorPassword $administratorPasswordSecure `
        -Verbose
}

Write-Host -fore green '[*] Finished forest installation'

##################################################################################
# Disable Antivirus
##################################################################################

if (Get-Module -ListAvailable -Name Defender) {
    Set-MpPreference `
        -DisableIntrusionPreventionSystem:$true `
        -DisableIOAVProtection:$true `
        -DisableRealtimeMonitoring:$true `
        -DisableScriptScanning:$true `
        -EnableControlledFolderAccess Disabled `
        -EnableNetworkProtection AuditMode `
        -Force `
        -MAPSReporting Disabled `
        -SubmitSamplesConsent NeverSend
}
