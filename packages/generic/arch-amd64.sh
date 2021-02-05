#!/bin/bash

##
## This script outputs the architecture of this system in order to build
## a native package based on the current project sources.
##

set -e

# Get current architecture name according to kernel
kernel_arch="$(uname -m)"

# Replace x86_64 with amd64
if [[ "$(echo "$kernel_arch" | tr '[:upper:]' '[:lower:]')" = 'x86_64' ]]; then
    echo 'amd64'
else
    echo "$kernel_arch"
fi
