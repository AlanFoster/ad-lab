#!/bin/bash
set -euxo pipefail

# Executes a git pull if the git folder is present, otherwise a git clone is run
#
# @param git_url The git URL to clone
# @param dir The target directory
# @return void
function git_pull_or_clone() {
    local git_url=$1
    local dir=$2

    git -C "$dir" pull || git clone "$git_url" "$dir"
}

# Appends a string to the end of the file, unless the string is already present
#
# @param string The string to append
# @param file The file to append to
# @return void
function idempotent_append() {
    local string=$1
    local file=$2

    if ! grep -qF "$string" "$file"; then
        echo "$string" >> "$file"
    fi
}
