# Enforce best practices in Powershell
Set-StrictMode -Version 1.0
# Exit if a cmdlet fails
$ErrorActionPreference = "Stop"

Write-Host -fore green '[*] Creating AD Objects'
Set-Location 'c:/vagrant/scripts/windows/'

##################################################################################
# Organizational units
##################################################################################

$organizationalUnits = Get-Content -Raw -Path "dc01-organizational-units.json" | ConvertFrom-Json
$organizationalUnits | ForEach-Object {
    $createdOrganizalUnit = Get-ADOrganizationalUnit -Filter "DistinguishedName -Eq '$($_.distinguishedName)'"
    if (!$createdOrganizalUnit) {
        # https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ldap/distinguished-names
        $nameRdn, $remainingRdns = $_.distinguishedName -Split ','
        $name = ($nameRdn -Split '=')[1]
        $path = $remainingRdns -Join ','
        Write-Host -Fore green "[*] Creating AD organizational unit name=$name path=$path"
        New-ADOrganizationalUnit -Name $name -Path $path
        $createdOrganizalUnit = Get-ADOrganizationalUnit -Filter "DistinguishedName -Eq '$($_.distinguishedName)'"
    }
}

##################################################################################
# Users
##################################################################################

$users = Get-Content -Raw -Path "dc01-users.json" | ConvertFrom-Json
$users | ForEach-Object {
    $username = $_.username
    $passwordSecure = ConvertTo-SecureString $_.password -AsPlainText -Force
    $ouPath = $_.ouPath

    # Either create a new user, or update the existing user's details
    $adUser = Get-ADUser -Filter "Name -Eq '$username'"
    if (!$adUser) {
        Write-Host -Fore green "[*] Creating new user $username"
        New-ADUser -Name $username
        $adUser = Get-ADUser -Filter "Name -Eq '$username'"
    }

    Write-Host -Fore green "[*] Setting properties on $username"
    $adUser | Set-ADUser `
        -PasswordNeverExpires:$true `
        -Enabled:$_.enabled
    $adUser | Set-ADAccountPassword `
        -NewPassword $passwordSecure
    if ($adUser.DistinguishedName -Ne "CN=$username,$ouPath") {
        $adUser | Move-ADObject -TargetPath $ouPath
    }
}
