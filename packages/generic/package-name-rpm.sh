#!/bin/bash

##
## This script outputs the filename of a rpm package based on the current
## project sources.
##

set -e

# Directory this script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

# Version string for this package
VERSION="$("${SCRIPT_DIR}/version.sh")"

# Revision string for this package
REVISION="$("${SCRIPT_DIR}/revision.sh")"

# Architecture for this package
ARCH="$("${SCRIPT_DIR}/arch.sh")"

echo "gpg-gui-${VERSION}-${REVISION}.${ARCH}.rpm"
