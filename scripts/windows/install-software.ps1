# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

##################################################################################
# Choco
##################################################################################

Write-Host -fore green '[*] Installing Choco software'

Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install -y --limit-output nmap wireshark googlechrome

##################################################################################
# Misc
##################################################################################

# Disable QuickEdit which can cause cmd.exe to hang until user input is received
# https://stackoverflow.com/questions/30418886/how-and-why-does-quickedit-mode-in-command-prompt-freeze-applications
# TODO: HKEY_CURRENT_USER Won't work for all users, a different solution is required
# Set-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Console" -Name "QuickEdit" -Value $false
