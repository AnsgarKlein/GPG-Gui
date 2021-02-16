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
## necessary for .rpm spec file.
output() {
    # Output dependencies (one per line)
    local dep
    for dep in "${DEPENDENCIES[@]}"; do
        echo "Requires: ${dep}"
    done
}


# Change to script directory
cd "$(dirname "$0")"
    
# Read dependency file
read_dependencies 'dependencies.txt'

# Output dependencies in required format
output
