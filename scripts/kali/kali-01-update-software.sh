#!/bin/bash
set -euxo pipefail

export vagrant_files=/vagrant/scripts/kali
source $vagrant_files/common.sh

##################################################################################
# APT
##################################################################################

export DEBIAN_FRONTEND=noninteractive

apt-get -q update
packages=(
    # Install the latest Kali metasploit-framework release
    metasploit-framework
    # Install the dependencies for local metasploit-framework development builds
    autoconf
    build-essential
    libpcap-dev
    libpq-dev
    zlib1g-dev
    libsqlite3-dev
    # CrackMapExec - SMB/WinRM/etc enumeration - https://github.com/Porchetta-Industries/CrackMapExec
    cme
    # Active Directory configuration viewer - https://github.com/BloodHoundAD/BloodHound
    bloodhound
    # Web application scanner
    nikto
    # Visual studio code for file editing
    code-oss
    # Copy/paste suport via the command line
    xsel
)
apt-get -yq install ${packages[@]}

##################################################################################
# Bloodhound Configuration
##################################################################################

/usr/share/neo4j/bin/neo4j-admin set-initial-password bloodhound

##################################################################################
# Wordlists
##################################################################################

# Extract rockyou wordlist
if [[ ! -e /usr/share/wordlists/rockyou.txt ]]; then
    gzip --decompress --keep /usr/share/wordlists/rockyou.txt.gz
fi

##################################################################################
# DNS
##################################################################################

# For now we don't write the DC to /etc/resolve.conf to avoid always running the DC
idempotent_append "10.10.10.5 dc01.demo.local demo.local" "/etc/hosts"
idempotent_append "10.10.10.6 ws01.demo.local" "/etc/hosts"
idempotent_append "10.10.11.5 dc02.dev.demo.local dev.demo.local" "/etc/hosts"
