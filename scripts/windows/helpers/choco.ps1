# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

# Install the chocolatey package manager
function Install-Choco() {
    Set-ExecutionPolicy Bypass -Scope Process -Force;
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Get existing choco install details as a string, or as $null if the package is not installed
function Get-LocalChocoPackageDetails (
    [string]$package
) {
    $packageDetails = choco list --localonly $package --exact --all --limitoutput
    if ($packageDetails) {
        return $packageDetails
    }
    return $null
}

# The default choco can fail to install. This function wraps the installation process with retry behavior
function Install-Choco-With-Retries {
    [CmdletBinding()]
    Param
    (
        [parameter(mandatory=$true, position=0)][string]$package,
        [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$arguments
    )

    # Checking for existing install details is faster and quieter than running choco install again
    $existingChocoInstallDetails = Get-LocalChocoPackageDetails $package
    if ($existingChocoInstallDetails) {
        Write-Host "[*] Skipping previously installed $package - found $existingChocoInstallDetails"
        return
    }

    $retryCount = 0;
    $maximumRetryCount = 10;
    $sleepMilliseconds = 20000
    $lastException = $null;

    do {
        Write-Host "[*] Starting choco install $package $arguments"
        try {
            & choco install -y $package @arguments
        } catch {
            $lastException = $_
        }

        $installedPackage = Get-LocalChocoPackageDetails $package
        if ($installedPackage) {
            Write-Host "[*] Installed $package - $installedPackage"
            return
        }

        if ($retryCount -lt $maximumRetryCount) {
            Write-Host "[!] Re-attempting choco install $($retryCount + 1)/$maximumRetryCount"
            Start-Sleep -Milliseconds $sleepMilliseconds
        }
        $retryCount += 1
    } while ($retryCount -lt $maximumRetryCount)

    # Retries exhausted, output a generic error or the last error we caught
    if ($lastException) {
        Write-Error "[!] Error $($lastException.Exception.InnerException.Message)"
    } else {
        Write-Error "[!] Error installing choco $package - package not installed locally after retrying $retryCount times"
    }
    throw "Error installing choco $package - package not installed locally after retrying $retryCount times"
}
