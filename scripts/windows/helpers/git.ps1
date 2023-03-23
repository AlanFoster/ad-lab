# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

$scriptsRoot = "c:\vagrant\scripts\windows";
if (!(Test-Path -Path $scriptsRoot)) {
    $scriptsRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
}

. $scriptsRoot\helpers\choco.ps1
. $scriptsRoot\helpers\invoke-nativecommandwitherrorcheck.ps1

# Install Git
function Install-Git() {
    Install-Choco-With-Retries -package git -arguments "--params `"'/GitAndUnixToolsOnPath /NoAutoCrlf'`""
}

# Install the Git repo, or perform a Git fetch if it already exists
function Install-GitRepo([string]$git_url, [string]$dir) {
    if (Test-Path -PathType Container -Path $dir) {
        Invoke-NativeCommandWithErrorCheck git -C "$dir" fetch --all
    } else {
        Invoke-NativeCommandWithErrorCheck git clone "$git_url" "$dir"
    }
}
