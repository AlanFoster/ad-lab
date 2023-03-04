#!/bin/bash
set -euxo pipefail

export vagrant_files=/vagrant/scripts/kali
source $vagrant_files/common.sh

export user_directory=~

#################################################################################
# Metasploit setup
#################################################################################

git_fetch_or_clone https://github.com/rapid7/metasploit-framework $user_directory/metasploit-framework
idempotent_append '[remote "upstream"]' "$user_directory/metasploit-framework/.git/config"
idempotent_append '	url = https://github.com/rapid7/metasploit-framework.git' "$user_directory/metasploit-framework/.git/config"
idempotent_append '	fetch = +refs/heads/*:refs/remotes/upstream/*' "$user_directory/metasploit-framework/.git/config"
idempotent_append '	fetch = +refs/pull/*/head:refs/remotes/upstream/pr/*' "$user_directory/metasploit-framework/.git/config"
(
    cd $user_directory/metasploit-framework
    bundle
)

#################################################################################
# Toolbox - File server, payload/shell generation, and useful tools like linpeas
#################################################################################

git_fetch_or_clone https://github.com/AlanFoster/toolbox.git $user_directory/toolbox
(
    cd $user_directory/toolbox
    git submodule update --init --recursive
    python3 -m pip install -r requirements.txt
    python3 $user_directory/toolbox/toolbox.py --help
)

##################################################################################
# Dirsearch - Python directory explorer, with recursive searching and wordlist
##################################################################################

git_fetch_or_clone https://github.com/maurosoria/dirsearch.git $user_directory/dirsearch
(
    cd $user_directory/dirsearch
    python3 -m pip install -r requirements.txt
    python3 $user_directory/dirsearch/dirsearch.py --help
)

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
comm -23 <(sort "$vagrant_files/.zsh_history") <(sort "$user_directory/.zsh_history") >> "$user_directory/.zsh_history"

##################################################################################
# Terminal configuration
##################################################################################

mkdir -p "$user_directory/.config/qterminal.org" 2>/dev/null || true
cp -f $vagrant_files/qterminal.ini "$user_directory/.config/qterminal.org/qterminal.ini"
