# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

# Disable antivirus if windows defender is present on the host
function Disable-Antivirus() {
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
}
