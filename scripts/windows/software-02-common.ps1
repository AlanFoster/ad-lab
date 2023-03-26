# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

$scriptsRoot = "c:\vagrant\scripts\windows";
if (!(Test-Path -Path $scriptsRoot)) {
    $scriptsRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
}

. $scriptsRoot\helpers\invoke-nativecommandwitherrorcheck
. $scriptsRoot\helpers\choco.ps1
. $scriptsRoot\helpers\update-sessionenvironment.ps1
. $scriptsRoot\helpers\vscode.ps1

##################################################################################
# Choco
##################################################################################

Write-Host -fore green '[*] Installing Choco software'

# Install-Choco-With-Retries -package nmap
# Install-Choco-With-Retries -package wireshark
# Update-SessionEnvironment

Install-Choco-With-Retries -package googlechrome

# vscode
Install-Vscode
Update-SessionEnvironment
Install-VscodeExtension -extension vscodevim.vim
Install-VscodeExtension -extension eamodio.gitlens
Install-VscodeExtension -extension ms-azuretools.vscode-docker

##################################################################################
# Misc
##################################################################################

# Disable QuickEdit which can cause cmd.exe to hang until user input is received
# https://stackoverflow.com/questions/30418886/how-and-why-does-quickedit-mode-in-command-prompt-freeze-applications
# TODO: HKEY_CURRENT_USER Won't work for all users, a different solution is required
# Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Console" -Name "QuickEdit" -Value $false
