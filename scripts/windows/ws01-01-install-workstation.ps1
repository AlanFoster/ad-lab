# Example usage:
# powershell.exe -file .\WS01-01-install-workstation.ps1 -domain demo.local -domainIp 10.10.10.5 -administratorPassword vagrant
param (
    [parameter(Mandatory=$true)]
    [string]$domain,

    [parameter(Mandatory=$true)]
    [string]$domainIp,

    [parameter(Mandatory=$true)]
    [string]$domainAdministratorPassword,

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
#$domainSubnet = $domainIp.Split('.')[0..2] -Join '.'
$adapters = Get-WmiObject "Win32_NetworkAdapterConfiguration where IPEnabled='TRUE'" # | Where-Object { $_.IPAddress -Match $domainSubnet }
$adapters | ForEach-Object {
    Write-Host -fore green "[*] Updating network adapter for $($_.IPAddress) to resolve DNS to $domainIp"
    $_.SetDNSServerSearchOrder($domainIp)
}

#####################################################################################
# Workstation installation
#####################################################################################

Write-Host -fore green '[*] Running workstation installation'
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

#
# Add Computer to the AD environment
#

# Win32_operatingSystem ProductType
#   Work Station (1)
#   Domain Controller (2)
#   Server (3)
# https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-operatingsystem
$isWorkstation = (Get-WmiObject -Class Win32_operatingSystem).ProductType -Eq 1
Write-Host -fore green "[*] isWorkstation=$isWorkstation"
if (!$isWorkstation) {
    Write-Host -fore green "[*] Adding computer $(hostname) to domain $domain"

    Write-Host "Using password: $($domainAdministratorPassword)"
    $safeDomainAdministratorPassword = ConvertTo-SecureString $domainAdministratorPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential("$domain\Administrator", $safeDomainAdministratorPassword)

    Add-Computer `
        -Credential $credential `
        -Domain $domain `
        -Force:$true `
        -Restart:$false `
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
