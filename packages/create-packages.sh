#!/bin/bash

set -e
source "$(dirname "$0")/common.sh"

main() {
    # Check that no arguments were given
    if [[ "$#" -ne 0 ]]; then
        echo "Error - Expected 0 arguments but $# were given" > /dev/stderr
        exit 1
    fi

    # Setup directory to exchange data with containers
    setup_container_exchange

    # Create packages in all available containers
    create_packages
}

main "$@"
