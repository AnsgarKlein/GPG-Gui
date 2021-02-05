#!/bin/bash

set -e
source "$(dirname "$0")/common.sh"

main() {
    # Check that an argument was given
    if [[ "$#" -ne 1 ]]; then
        echo "Error - Expected 1 argument but $# were given" > /dev/stderr
        echo ''
        echo "Usage: $0 DIR"
        echo "Where DIR is the directory containing the container used to create a package"
        exit 1
    fi

    # Setup directory to exchange data with containers
    setup_container_exchange

    # Create package in given container
    create_package "${SCRIPT_DIR}/${1}"
}

main "$@"
