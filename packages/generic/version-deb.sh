#!/bin/bash

##
## This script outputs the version of a debian package based on the current
## project sources.
##

set -e

# Directory this script is located in
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Root directory of this project
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Upstream version of this application
UPSTREAM_VERSION="$("${PROJECT_ROOT}/scripts/version.sh")"
VERSION="$UPSTREAM_VERSION"

# Append build target to version
VERSION="${VERSION}+$(basename "$SCRIPT_DIR")"

echo "$VERSION"
