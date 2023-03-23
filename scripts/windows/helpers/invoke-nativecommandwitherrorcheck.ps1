# Attempt the native command, or raise if $LASTEXITCODE was non-zero.
# There is native support for this functionality via 'PSNativeCommandErrorActionPreference' - but it's still experimental in Powershell 7.3
# https://github.com/PowerShell/PowerShell/issues/3415
# https://learn.microsoft.com/en-us/powershell/scripting/learn/experimental-features?view=powershell-7.3

# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"
function Invoke-NativeCommandWithErrorCheck {
    [CmdletBinding()]
    Param
    (
        [parameter(mandatory=$true, position=0)][string]$name,
        [parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$arguments
    )
    $retryCount = 0;
    $maximumRetryCount = 10;
    $sleepMilliseconds = 20000;
    $lastException = $null;

    do {
        Write-Host "[*] Starting '$name $($arguments -Join ' ')'"

        try {
            $result = & $name @arguments
            if ($LASTEXITCODE -Eq 0) {
                return $result
            }
        } catch {
            $lastException = $_
        }

        if ($retryCount -lt $maximumRetryCount) {
            Write-Host "[!] Re-attempting '$name $($arguments -Join ' ')' $($retryCount + 1)/$maximumRetryCount"
            Start-Sleep -Milliseconds $sleepMilliseconds
        }
        $retryCount += 1
    } while ($retryCount -lt $maximumRetryCount)

    # Retries exhausted

    # Retries exhausted, output a generic error or the last error we caught
    if ($lastException) {
        Write-Error "[!] Error  Executing '$name $($arguments -Join ' ')' failed with $($lastException.Exception.InnerException.Message)"
    } else {
        Write-Error "[!] Error Executing '$name $($arguments -Join ' ')' Failed with $LASTEXITCODE after $retryCount times"
    }
    throw "Executing '$name $($arguments -Join ' ')' Failed with $LASTEXITCODE after $retryCount times"
}
