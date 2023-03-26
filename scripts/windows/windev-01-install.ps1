# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

$scriptsRoot = "c:\vagrant\scripts\windows";
if (!(Test-Path -Path $scriptsRoot)) {
    $scriptsRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
}

. $scriptsRoot\helpers\choco.ps1
. $scriptsRoot\helpers\update-sessionenvironment.ps1
. $scriptsRoot\helpers\git.ps1
. $scriptsRoot\helpers\antivirus.ps1


##################################################################################
# Disable Antivirus
##################################################################################

Disable-Antivirus

##################################################################################
# Git
##################################################################################

Install-Git
Update-SessionEnvironment

##################################################################################
# Useful tools
##################################################################################

# Process monitoring for finding DLL path injections etc
Install-Choco-With-Retries -package procmon

# Fast alternative to using the default file explorer
Install-Choco-With-Retries -package everything

# Multiple quality of life improvements
Install-Choco-With-Retries -package powertoys

##################################################################################
# Metasploit - Cloning framework plus installing all of the payload runtimes
##################################################################################

Install-Choco-With-Retries -package 7zip
Install-Choco-With-Retries -package php
Install-Choco-With-Retries -package python

# Log in with: psql "postgres://postgres:vagrant@localhost:5432"
Install-Choco-With-Retries -package postgresql12 --params '/Password:vagrant /Port:5432' --installargs '--enable-components commandlinetools'

Update-SessionEnvironment

Install-GitRepo https://github.com/rapid7/metasploit-framework.git c:/metasploit-framework

# pcaprub, required for bundle install
$winPcapZip = 'C:\Windows\Temp\WpdPack_4_1_2.zip'
if (!(Test-Path -Path $winPcapZip)) {
    (New-Object System.Net.WebClient).DownloadFile('https://www.winpcap.org/install/bin/WpdPack_4_1_2.zip', $winPcapZip)
}
Invoke-NativeCommandWithErrorCheck 7z x $winPcapZip -aoa -o"C:\"
# Copy-Item -Force C:\WpdPack\Lib\x64\Packet.lib C:\WpdPack\Lib\
# Copy-Item -Force C:\WpdPack\Lib\x64\wpcap.lib C:\WpdPack\Lib\

# ruby 3.0.x is only supported with winpcap: https://github.com/pcaprub/pcaprub/issues/62
Install-Choco-With-Retries -package ruby --version=3.0.5.1
# install msys2 without system update
Install-Choco-With-Retries -package msys2 --params "/NoUpdate"
Update-SessionEnvironment

# use ruby's ridk to update the system and install development toolchain
Invoke-NativeCommandWithErrorCheck ridk install 2 3
Update-SessionEnvironment

Set-Location C:/metasploit-framework
Invoke-NativeCommandWithErrorCheck bundle

##################################################################################
# Visual studio
##################################################################################

Invoke-WebRequest -Uri https://raw.githubusercontent.com/rapid7/metasploit-payloads/master/c/meterpreter/vs-configs/vs2019.vsconfig -OutFile c:/windows/temp/vs2019.vsconfig
Install-Choco-With-Retries -package visualstudio2019community --package-parameters "--config c:/windows/temp/vs2019.vsconfig"
