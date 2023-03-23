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
function Install-Vscode() {
    Install-Choco-With-Retries -package vscode
}

# Get existing vscode install details as a string, or as $null if the extension is not installed
function Get-LocalVscodeExtensionDetails(
    [string]$extension
) {
    $extensionDetails = code --list-extensions | findstr $extension
    if ($extensionDetails) {
        return $extensionDetails
    }
    return $null
}

# Install the VSCode extension
function Install-VscodeExtension(
    [string]$extension,
    [string[]]$arguments = @()
) {
    # Checking for existing install details is faster and quieter than running install again
    $existingDetails = Get-LocalVscodeExtensionDetails $extension
    if ($existingDetails) {
        Write-Host "[*] Skipping previously installed $extension - found $existingDetails"
        return
    }

    $retryCount = 0;
    $maximumRetryCount = 10;
    $sleepMilliseconds = 20000
    $lastException = $null;

    do {
        Write-Host "[*] Starting extension install $extension $arguments"
        try {
            Invoke-NativeCommandWithErrorCheck code --install-extension $extension
        } catch {
            $lastException = $_
        }

        $installedextension = Get-LocalVscodeExtensionDetails -extension $extension
        if ($installedextension) {
            Write-Host "[*] Installed $extension - $installedextension"
            return
        }

        if ($retryCount -lt $maximumRetryCount) {
            Write-Host "[!] Re-attempting $($retryCount + 1)/$maximumRetryCount"
            Start-Sleep -Milliseconds $sleepMilliseconds
        }
        $retryCount += 1
    } while ($retryCount -lt $maximumRetryCount)

    # Retries exhausted, output a generic error or the last error we caught
    if ($lastException) {
        Write-Error "[!] Error $($lastException.Exception.InnerException.Message)"
    } else {
        Write-Error "[!] Error installing $extension - not installed locally after retrying $retryCount times"
    }
    throw "Error installing $extension - not installed locally after retrying $retryCount times"

    Invoke-NativeCommandWithErrorCheck git -C "$dir" fetch --all
}
