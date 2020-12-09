#!/bin/sh

###
### This script is a helper script for the Meson build system.
### It is automatically run in the build process in order to determine
### the version string for the current build.
###


# cd to directory of script
if ! cd "$(dirname "$0")"; then
    echo 'Could not cd to script directory' 2> /dev/stderr
    exit 1
fi

# Get version from git tags
VERSION="$(git describe --tags --long --match 'v[0-9]*' --dirty --broken)"

# Remove 'v' prefix from version string
VERSION="$(echo "$VERSION" | sed 's/^v//')"

# Error if version string is empty
if [ -z "$VERSION" ]; then
    exit 1
fi

echo "$VERSION"
