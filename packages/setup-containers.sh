#!/bin/bash

set -e
source "$(dirname "$0")/common.sh"

main() {
    # Check that no arguments were given
    if [[ "$#" -ne 0 ]]; then
        echo "Error - Expected 0 arguments but $# were given" > /dev/stderr
        exit 1
    fi

    # Build images for all containers
    setup_containers
}

main "$@"
