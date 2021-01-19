#!/bin/sh

###
### This script is a helper script for the Meson build system.
### It is automatically run in the build process in order to determine
### the version string for the current build.
###


# cd to directory of script
if ! cd "$(dirname "$0")"; then
    echo 'Could not cd to script directory' > /dev/stderr
    exit 1
fi

# Run git status
git status > /dev/null 2>&1

# Get version from git tags
GIT_DESCRIBE="git describe --tags --long --dirty --broken"
GIT_DESCRIBE="$GIT_DESCRIBE --match   v[0-9]*.[0-9]*.[0-9]*"
GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*[!0-9]*.*.*"
GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*.*[!0-9]*.*"
GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*.*.*[!0-9]*"
if ! VERSION="$($GIT_DESCRIBE)"; then
    echo 'git could not determine valid version string' > /dev/stderr
    exit 1
fi

# Remove 'v' prefix from version string
VERSION="$(echo "$VERSION" | sed 's/^v//')"

# Error if version string is empty
if [ -z "$VERSION" ]; then
    echo 'Could not determine valid version string' > /dev/stderr
    exit 1
fi

echo "$VERSION"
