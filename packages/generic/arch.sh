#!/bin/bash

##
## This script outputs the architecture of this system in order to build
## a native package based on the current project sources.
##

set -e

# Get current architecture name according to kernel
kernel_arch="$(uname -m)"

# Output
echo "$kernel_arch"
