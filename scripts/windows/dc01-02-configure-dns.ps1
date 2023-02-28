param (
    [parameter(Mandatory=$true)]
    [string]$hostname,

    [parameter(Mandatory=$true)]
    [string]$domain,

    [parameter(Mandatory=$true)]
    [string]$domainIp,

    [parameter(Mandatory=$true)]
    [string]$administratorPassword
)

# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

##################################################################################
# Additional DNS
##################################################################################

# Only resolve DNS to the ipv4 static address
# Implements Step 2 of: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/unwanted-nic-registered-dns-mulithomed-dc#resolution
#     Open the DNS server console, highlight the server on the left pane, and then select Action > Properties
#     On the Interfaces tab, select listen on only the following IP addresses. Remove unwanted IP address from the list.
Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters' -Name ListenAddresses -Type MultiString -Value $domainIp

# Remove any existing DNS A records from the domain that don't match the required domain IP
# This will remove any extra IP addreses that were unintentionally registered, i.e. virtualbox's
# default NAT adapter address
# Implements Step 3 of: https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/unwanted-nic-registered-dns-mulithomed-dc#resolution
#     On the Zone properties, select Name server tab. Along with FQDN of the DC, you'll see the IP address associated with the DC. Remove unwanted IP address if it's listed.
$dnsServerResourceRecords = Get-DnsServerResourceRecord -ZoneName $domain -RRType 'A'
$dnsServerResourceRecords | ForEach-Object {
    if ($_.RecordData.IPv4Address -Ne $domainIp) {
        Write-Host -Fore green "[*] Removing unneeded DNS Entry hostname=$($_.HostName) address=$($_.RecordData.IPv4Address)"
        # -ComputerName
        Remove-DnsServerResourceRecord `
            -ZoneName $domain `
            -RecordData $_.RecordData.IPv4Address `
            -Name $_.HostName `
            -RRType $_.RecordType `
            -Force
    }
}

# Ensure there's only a single A record entry for the hostname to resolve to the static IPv4 address
Remove-DnsServerResourceRecord -ZoneName $domain -RRType 'A' -Name $hostname.ToLowerInvariant() -Force
Add-DnsServerResourceRecordA -Name $hostname.ToLowerInvariant() -ZoneName $domain -IPv4Address $domainIp

Write-Host -fore green '[*] DNS records configured:'
Get-DnsServerResourceRecord -ZoneName $domain

# Configure DNS forwarding to Google's primary DNS server, to handle the sceanrio of resolving an external address like example.com
Remove-DnsServerForwarder (Get-DnsServerForwarder).IpAddress -Force
Add-DnsServerForwarder -IPAddress 8.8.8.8

##################################################################################
# Password policy
##################################################################################

function Wait-For-DomainController() {
    $retryCount = 0;
    $maximumRetryCount = 60;
    $sleepMilliseconds = 10000
    $lastException = $null
    do {
        try {
            Get-ADDomainController -DomainName $domain -Discover -Service ADWS -ErrorAction Stop
            return
        } catch {
            $lastException = $_
            if ($retryCount -lt $maximumRetryCount) {
                Write-Host "[!] Re-attempting $($retryCount + 1)/$maximumRetryCount - $($lastException.Exception.ToString())" -ErrorAction Continue
                Start-Sleep -Milliseconds $sleepMilliseconds
            }
            $retryCount += 1
        }
    } while ($retryCount -lt $maximumRetryCount)

    Write-Error "[!] Error $($lastException.Exception.InnerException.Message)" -ErrorAction Continue
    throw $lastException
}

# Allow weak AD passwords that never expire / require updating
Wait-For-DomainController
Set-ADDefaultDomainPasswordPolicy -Identity $domain -ComplexityEnabled:$false -MaxPasswordAge 0
Get-ADDefaultDomainPasswordPolicy

# Allow for the creation of a child domain controller, avoiding Access Denied errors:
# https://learn.microsoft.com/en-us/troubleshoot/windows-server/identity/access-denied-error-occurs-dcpromo
# https://www.vkernel.ro/blog/domain-controller-promotion-fails-with-access-is-denied
