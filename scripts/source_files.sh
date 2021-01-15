#!/bin/bash

###
### This script prints all vala source files for this project as relative
### paths starting at source directory.
###
### For consistency use the order this script outputs for defining sources
### in the the Meson build system.
###



# cd to directory of this script
if ! cd "$(dirname "$0")"; then
    echo 'Could not cd to script directory' > /dev/stderr
    exit 1
fi

# Relative path from this script to project root directory
PRJ_PATH='..'

# Relative path from this script to source directory
SRC_PATH="$PRJ_PATH/src"


# Global array that stores all vala source files
VALA_FILES=()



# Recursively add all files in given directory to global VALA_FILES array
#
# Arguments: $1 - directory to recursively add files
# Returns: -
vala_files() {
    # Check parameters
    if [ $# -ne 1 ]; then
        echo "Expected 1 parameter but got $# - error" > /dev/stderr
        exit 1
    fi
    if [ ! -d "$1" ]; then
        echo "Parameter \"$1\" is not a directory - error" > /dev/stderr
        exit 1
    fi
    local cur_dir="$1"

    # Get all files of the current dir
    local OLDIFS=$IFS
    IFS='
'
    for f in $(ls -1 "$cur_dir/"*.vala | sort --dictionary --version-sort); do
        if [ -f "$f" ]; then
            VALA_FILES+=("$f")
        fi
    done
    IFS=$OLDIFS

    # Get all subdirectories of the current dir
    local subdirs=()
    local OLDIFS=$IFS
    IFS='
'
    for d in $(ls -1 "$cur_dir" | sort --dictionary --version-sort); do
        if [ -d "$cur_dir/$d" ]; then
            subdirs+=("$cur_dir/$d")
        fi
    done
    IFS=$OLDIFS

    # Recursively call this function for all subdirectories
    for d in "${subdirs[@]}"; do
        vala_files "$d"
    done
}

# Remove given prefix from each element in global VALA_FILES
# array.
#
# Arguments: $1 - the prefix to remove
# Returns: -
remove_prefix() {
    # Check parameters
    if [ $# -ne 1 ]; then
        echo "Expected 1 parameter but got $# - error" > /dev/stderr
        exit 1
    fi
    if [ -z "$1" ]; then
        echo "Got empty string as parameter - error" > /dev/stderr
        exit 1
    fi
    local prefix=$1

    # Remove prefix from each element in array
    for i in "${!VALA_FILES[@]}"; do
        local element
        element=${VALA_FILES[$i]}
        element=${element/#"$prefix/"/}

        VALA_FILES[$i]=$element
    done
}

# Main function
main() {
    # cd to directory above source directory
    if ! cd "$SRC_PATH/.."; then
        echo 'Could not cd above source directory' > /dev/stderr
        exit 1
    fi

    # Recursively get all vala source files starting at source directory
    local src_dir
    src_dir="$(basename "$SRC_PATH")"
    vala_files "$src_dir"

    # Remove source directory prefix from every path
    remove_prefix "$src_dir"

    # Print out all vala source files
    for element in "${VALA_FILES[@]}"; do
        echo "$element"
    done
}

main
