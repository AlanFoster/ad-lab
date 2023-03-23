# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

$scriptsRoot = "c:\vagrant\scripts\windows";
if (!(Test-Path -Path $scriptsRoot)) {
    $scriptsRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
}

. $scriptsRoot\helpers\choco.ps1

##################################################################################
# Choco
##################################################################################

Write-Host -fore green '[*] Installing Choco software'
Install-Choco
