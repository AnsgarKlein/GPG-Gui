#!/bin/bash

##
## This script outputs the runtime dependencies necessary for a package
## build on this platform.
##


set -e

# Array holding all dependencies
declare -a DEPENDENCIES


## Function that reads dependency file where
## every line contains exactly one dependency definition.
## Arguments:
##  $1: Path to file containing dependencies
read_dependencies() {
    # Parse argument
    if [[ -z "$1" ]]; then
        echo 'Error - No dependency file given!' > /dev/stderr
        exit 1
    fi
    local file_name="$1"

    # Check if file exists
    if [[ ! -f "$file_name" ]]; then
        echo "Error - Dependency file \"$file_name\" does not exist" > /dev/stderr
        exit 1
    fi

    # Read dependencies from file
    local line
    while read -r line; do
        DEPENDENCIES+=("$line")
    done <<< "$(sort -d < "$file_name")"
}


## Function that outputs dependencies in a format
## necessary for .deb control file.
output() {
    # Format dependencies
    local output='Depends:'
    local dep
    for dep in "${DEPENDENCIES[@]}"; do
        output="${output} ${dep},"
    done

    # Remove last delimiter if necessary
    if [[ "$(echo "$output" | rev | cut -c 1 | rev)" = ',' ]]; then
        output="$(echo "$output" | rev | cut -c 2- | rev)"
    fi

    echo "$output"
}


# Change to script directory
cd "$(dirname "$0")"
    
# Read dependency file
read_dependencies 'dependencies.txt'

# Output dependencies in required format
output
