#!/bin/bash

# cd to directory of script
if ! cd "$(dirname "$0")"; then
    echo 'Could not cd to script directory' 2> /dev/stderr
    exit 1
fi

git describe --tags --long --match 'v[0-9]*' --dirty --broken
