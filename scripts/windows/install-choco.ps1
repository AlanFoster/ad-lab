$scriptsRoot = "c:\vagrant\scripts\windows";
if (!(Test-Path -Path $scriptsRoot)) {
    $scriptsRoot = (Split-Path -parent $MyInvocation.MyCommand.Definition)
}

. $scriptsRoot\helpers\choco.ps1

Install-Choco
Install-Choco-With-Retries -package openssh --package-parameters=/SSHServerFeature openssh
