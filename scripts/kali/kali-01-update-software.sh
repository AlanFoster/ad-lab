#!/bin/bash
set -euxo pipefail

##################################################################################
# APT
#################################################################################

apt-get update
apt-get -y install metasploit-framework cme
