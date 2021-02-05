#!/bin/bash

set -e
source "$(dirname "$0")/common.sh"

main() {
    # Check that an argument was given
    if [[ "$#" -ne 1 ]]; then
        echo "Error - Expected 1 argument but $# were given" > /dev/stderr
        echo ''
        echo "Usage: $0 DIR"
        echo "Where DIR is the directory containing the container to setup"
        exit 1
    fi

    # Build image for given container
    setup_container "${SCRIPT_DIR}/${1}"
}

main "$@"
