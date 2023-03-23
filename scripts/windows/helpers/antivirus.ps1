# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

# Disable antivirus if windows defender is present on the host
function Disable-Antivirus() {
    if (Get-Module -ListAvailable -Name Defender) {
        Set-MpPreference -DisableRealtimeMonitoring $true
        New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" -Name DisableAntiSpyware -Value 1 -PropertyType DWORD -Force
    }
}
