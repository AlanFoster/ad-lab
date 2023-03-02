#!/bin/bash
set -euxo pipefail

##################################################################################
# Toolbox - File server, payload/shell generation, and useful tools like linpeas
#################################################################################

export user_directory=~

# Pull or update
git -C $user_directory/toolbox pull || git clone https://github.com/AlanFoster/toolbox.git $user_directory/toolbox
cd $user_directory/toolbox
git submodule update --init --recursive
pip3 install -r requirements.txt
python3 $user_directory/toolbox/toolbox.py --help
