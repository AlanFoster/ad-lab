#!/bin/bash
set -euxo pipefail

export vagrant_files=/vagrant/scripts/kali
source $vagrant_files/common.sh

export user_directory=~

#################################################################################
# Toolbox - File server, payload/shell generation, and useful tools like linpeas
#################################################################################

git_pull_or_clone https://github.com/AlanFoster/toolbox.git $user_directory/toolbox
cd $user_directory/toolbox
git submodule update --init --recursive
python3 -m pip install -r requirements.txt
python3 $user_directory/toolbox/toolbox.py --help

##################################################################################
# Dirsearch - Python directory explorer, with recursive searching and wordlist
##################################################################################

git_pull_or_clone https://github.com/maurosoria/dirsearch.git $user_directory/dirsearch
cd $user_directory/dirsearch
python3 -m pip install -r requirements.txt
python3 $user_directory/dirsearch/dirsearch.py --help

##################################################################################
# .zsh_rc configuration
##################################################################################

# Load our custom zshrc configuration
cp -f "$vagrant_files/.zshrc_custom" "$user_directory"
chmod 0644 "$user_directory/.zshrc_custom"
idempotent_append ". $user_directory/.zshrc_custom" "$user_directory/.zshrc"

# Ensure command history isn't truncated
sed -i 's/HISTSIZE=.*/HISTSIZE=10000000/' "$user_directory/.zshrc"
sed -i 's/SAVEHIST=.*/SAVEHIST=10000000/' "$user_directory/.zshrc"

# Append any missing history lines to .zsh_history
touch "$user_directory/.zsh_history"
chmod 0644 "$user_directory/.zsh_history"
comm -23 <(sort -i "$vagrant_files/.zsh_history") <(sort -i "$user_directory/.zsh_history") >> "$user_directory/.zsh_history"

##################################################################################
# Terminal configuration
##################################################################################

# Support the same navigation shortcuts as iterm, shift+cmd+left and shift+cmd+right for tab navigation
if [[ ! -e "$user_directory/.config/qterminal.org/qterminal.ini" ]]; then
    cp /usr/share/kali-themes/etc/xdg/qterminal.org/qterminal.ini "$user_directory/.config/qterminal.org/qterminal.ini"
fi

idempotent_append "Move%20Tab%20Left=" "$user_directory/.config/qterminal.org/qterminal.ini"
sed -i 's/Move%20Tab%20Left=.*/Move%20Tab%20Left=Alt+Shift+Left|Ctrl+Shift+PgUp/' "$user_directory/.config/qterminal.org/qterminal.ini"

idempotent_append "Move%20Tab%20Right=" "$user_directory/.config/qterminal.org/qterminal.ini"
sed -i 's/Move%20Tab%20Right=.*/Move%20Tab%20RightAlt+Shift+Right|Ctrl+Shift+PgDown0/' "$user_directory/.config/qterminal.org/qterminal.ini"
