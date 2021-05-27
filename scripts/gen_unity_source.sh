#!/bin/bash

###
### This script is a helper script for the Meson build system.
### If creates a unity source file from given input source files:
### It takes all given input files and concatenates them to one single
### output file.
### Giving this single output file to compiler may speed up compilation
### and result in faster code. It obviously breaks incremental builds though.
###


print_help() {
    echo "Usage: $0 <input-file1> <input-file2> <...> --output <output-file>"
}


# Array of files to use for input
INPUT_FILES=()

# File to use for output
OUTPUT_FILE=''


# There have to be at least 3 parameters:
# <input-file1> --output <output-file>
if [ $# -lt 3 ]; then
    print_help
    exit 1
fi

# Read all parameters
while (($#)); do
    if [ "$1" = '--help' ] | [ "$1" = '-h' ]; then
        print_help
        exit 1
    fi

    if [ "$1" = '--output' ]; then
        OUTPUT_FILE="$2"
        break
    fi

    INPUT_FILES+=("$1")
    shift
done

# Check if all input files exist
for file in "${INPUT_FILES[@]}"; do
    if ! [ -r "$file" ]; then
        echo "File \"$file\" is not readable" > /dev/stderr
        exit 1
    fi
done

# Check if output file is set
if [ -z "$OUTPUT_FILE" ]; then
    echo "Output file has not been set" > /dev/stderr
    exit 1
fi

# Concatenate all input files
cat "${INPUT_FILES[@]}" > "$OUTPUT_FILE"
