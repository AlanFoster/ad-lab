#!/bin/bash
set -euxo pipefail

##################################################################################
# APT
#################################################################################

export DEBIAN_FRONTEND=noninteractive

apt-get -q update
apt-get -yq install metasploit-framework cme bloodhound

##################################################################################
# Bloodhound
#################################################################################

/usr/share/neo4j/bin/neo4j-admin set-initial-password bloodhound
