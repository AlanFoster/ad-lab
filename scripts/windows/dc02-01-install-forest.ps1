# Example usage:
# powershell.exe -file .\dc02-01-install-forest.ps1 -parentDomain demo.local -parentDomainIp 10.10.10.5 -domain dev.demo.local -domainIp 10.10.10.6 -administratorPassword vagrant
param (
    [parameter(Mandatory=$true)]
    [string]$parentDomainIp,

    [parameter(Mandatory=$true)]
    [string]$parentDomain,

    # [parameter(Mandatory=$true)]
    # [string]$hostname,

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

# Allow weak local account passwords
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
Remove-Item -force c:\secpol.cfg -confirm:$false

#####################################################################################
# DNS Configuration
#####################################################################################

# Add DNS to preference root domain DNS lookup
#$parentDomainSubnet = $parentDomainIp.Split('.')[0..2] -Join '.'
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration # | Where-Object { $_.IPAddress -Match $parentDomainSubnet }
$adapters | ForEach-Object {
    Write-Host -fore green "[*] Updating network adaptor for $_.IPAddress to resolve DNS to $parentDomainIp"
    $_.SetDNSServerSearchOrder($parentDomainIp)
}

#####################################################################################
# Forest installation
#####################################################################################

Write-Host -fore green '[*] Running forest installation'
$safeModeAdministratorPassword = ConvertTo-SecureString $administratorPassword -AsPlainText -Force

# Set local Administrator account password to stop the error:
#   "The new domain cannot be created DC01: because the local Administrator account password does not meet requirements."
Write-Host -fore green '[*] Setting local administrator password'
Set-LocalUser `
    -Name Administrator `
    -AccountNeverExpires `
    -Password $safeModeAdministratorPassword `
    -PasswordNeverExpires:$true `
    -UserMayChangePassword:$true

Install-WindowsFeature AD-Domain-Services,RSAT-AD-AdminCenter,RSAT-ADDS-Tools -IncludeManagementTools -Verbose

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
    Import-Module ADDSDeployment
    $credential = New-Object System.Management.Automation.PSCredential("$parentDomain\Administrator", $safeModeAdministratorPassword)

    Install-ADDSDomain `
        -NoGlobalCatalog:$false `
        -CreateDnsDelegation:$true `
        -Credential $credential `
        -DatabasePath "C:\Windows\NTDS" `
        -DnsDelegationCredential $credential `
        -DomainMode "WinThreshold" `
        -DomainType "ChildDomain" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NewDomainName "dev" `
        -NewDomainNetbiosName "DEV" `
        -ParentDomainName $parentDomain `
        -NoRebootOnCompletion:$true `
        -SiteName "Default-First-Site-Name" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true `
        -SafeModeAdministratorPassword $safeModeAdministratorPassword `
        -Verbose
}

Write-Host -fore green '[*] Finished forest installation'

##################################################################################
# Disable Antivirus
##################################################################################

if (Get-Module -ListAvailable -Name Defender) {
    Set-MpPreference -DisableRealtimeMonitoring $true
    New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" -Name DisableAntiSpyware -Value 1 -PropertyType DWORD -Force
}
