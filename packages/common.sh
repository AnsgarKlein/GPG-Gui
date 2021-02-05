#!/bin/bash

if [[ -z "$GPG_GUI_PACKAGES_COMMON_SH" ]]; then

    set -e


    # Directory this script ist located
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"


    # Project root directory relative to this directory
    GPG_GUI_PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"


    # Exchange directory used for exchanging files with docker containers
    GPG_GUI_PKGBUILD_DIR="$(cd "${SCRIPT_DIR}/build" && pwd)"


    # Array holding all directories defining a container
    GPG_GUI_CONTAINER_DIRS=()
    setup_GPG_GUI_CONTAINER_DIRS() {
        GPG_GUI_CONTAINER_DIRS=()

        local script_dir
        script_dir="$(cd "$(dirname "$0")" > /dev/null 2>&1 && pwd)"

        local container_dir
        for container_dir in "$script_dir"/*; do
            if ! [[ -d "$container_dir"                 ]]; then continue ; fi
            if ! [[ -f "$container_dir/Dockerfile"      ]]; then continue ; fi
            if ! [[ -f "$container_dir/package.sh"      ]]; then continue ; fi
            if ! [[ -f "$container_dir/package-name.sh" ]]; then continue ; fi

            GPG_GUI_CONTAINER_DIRS+=("$container_dir")
        done
    }
    setup_GPG_GUI_CONTAINER_DIRS
    unset setup_GPG_GUI_CONTAINER_DIRS


    # ID of last container that was run (may be empty)
    CURRENT_CONTAINER_ID=''
    
    
    ## Function that stops and removes the currently running container
    ## (if any). Uses the CURRENT_CONTAINER_ID variable.
    function stop_current_container() {
        # Done if no container running
        if [[ -z "$CURRENT_CONTAINER_ID" ]]; then
            return
        fi

        # Run in background because this function might run on
        # Ctrl-C and we need to be fast before the user
        # aborts this function with a second Ctrl-C.
        docker rm -f "$CURRENT_CONTAINER_ID" > /dev/null 2>&1 || true &

        CURRENT_CONTAINER_ID=''
    }


    ## Function that builds a given container image
    ## Arguments:
    ##  $1: Absolute path to the directory containing the Dockerfile to build
    setup_container() {
        # Parse variables
        if [[ -z "$1" ]]; then
            echo 'Error - No container directory given!' > /dev/stderr
            exit 1
        fi
        local container_dir="$1"

        # Check if given container dir is valid
        local found=''
        local dir
        for dir in "${GPG_GUI_CONTAINER_DIRS[@]}"; do
            if [[ "$dir" = "$container_dir" ]]; then
                found='yes'
                container_dir="$dir"
                break
            fi
        done
        if [[ -z "$found" ]]; then
            echo "Error - given container directory \"$container_dir\" is not valid!" > /dev/stderr
            exit 1
        fi

        local container_image
        container_image="gpg-gui-builder-$(basename "$container_dir")"
        local dockerfile="${container_dir}/Dockerfile"

        echo ''
        echo '#################################################################'
        echo "## Setting up container image \"$container_image\""
        echo '#################################################################'
        echo ''

        # Build docker image
        docker build -t "$container_image" \
        --cache-from "$container_image" \
        - < "$dockerfile"
    }


    ## Function that builds all available container images
    setup_containers() {
        local container_dir
        for container_dir in "${GPG_GUI_CONTAINER_DIRS[@]}"; do
            setup_container "$container_dir"
        done
    }


    ## Function that creates the directory for exchanging files with
    ## containers. Also creates source archive in this directory.
    setup_container_exchange() {
        # Create exchange directory
        if ! [ -d "$GPG_GUI_PKGBUILD_DIR" ]; then
            mkdir -p "$GPG_GUI_PKGBUILD_DIR"
        fi

        if [ -z "$GPG_GUI_ARCHIVE" ]; then
            # Create archive and save name of archive (relative to project root)
            GPG_GUI_ARCHIVE="$("${GPG_GUI_PROJECT_ROOT}/scripts/create-tarball.sh")"

            # Move archive to exchange directory
            mv "${GPG_GUI_PROJECT_ROOT}/${GPG_GUI_ARCHIVE}" "$GPG_GUI_PKGBUILD_DIR/"
        fi
    }


    ## Function that creates a package using a given container.
    ## This requires a directory to exchange data with this container,
    ## which has to be setup before calling this function.
    ## Arguments:
    ##  $1: Absolute path to the directory containing the Dockerfile
    create_package() {
        # Parse variables
        if [[ -z "$1" ]]; then
            echo 'Error - No container directory given!' > /dev/stderr
            exit 1
        fi
        local container_dir="$1"

        # Check if given container dir is valid
        local found=''
        local dir
        for dir in "${GPG_GUI_CONTAINER_DIRS[@]}"; do
            if [[ "$dir" = "$container_dir" ]]; then
                found='yes'
                container_dir="$dir"
                break
            fi
        done
        if [[ -z "$found" ]]; then
            echo "Error - given container directory \"$container_dir\" is not valid!" > /dev/stderr
            exit 1
        fi

        # Setup container
        setup_container "$container_dir"

        local container_image
        container_image="gpg-gui-builder-$(basename "$container_dir")"

        local pkg_name_script="${container_dir}/package-name.sh"
        local pkg_name
        pkg_name="$("$pkg_name_script")"

        # Make path to package script relative to project root
        local container_package_script="${container_dir}/package.sh"
        container_package_script="${container_package_script/#${GPG_GUI_PROJECT_ROOT}/}"
        container_package_script="${container_package_script/#\//}"

        # Make path to package build dir relative
        local container_pkgbuild_dir="$GPG_GUI_PKGBUILD_DIR"
        container_pkgbuild_dir="${container_pkgbuild_dir/#${GPG_GUI_PROJECT_ROOT}/}"
        container_pkgbuild_dir="${container_pkgbuild_dir/#\//}"

        # Create container from image and run in background
        CURRENT_CONTAINER_ID=$(docker run \
        --volume "${GPG_GUI_PKGBUILD_DIR}:/mnt" \
        --security-opt=apparmor=unconfined \
        --security-opt=label=disable \
        --tty \
        --detach \
        --workdir '/app' \
        "$container_image")

        # Extract archive from host build dir to container workspace
        docker exec "$CURRENT_CONTAINER_ID" tar -xf "/mnt/${GPG_GUI_ARCHIVE}"

        # Build package inside container
        docker exec "$CURRENT_CONTAINER_ID" "$container_package_script"

        # Move resulting file from container build dir to host build dir
        docker exec "$CURRENT_CONTAINER_ID" sudo mv -f "${container_pkgbuild_dir}/${pkg_name}" "/mnt"
        docker exec "$CURRENT_CONTAINER_ID" sudo chown "0:0" "/mnt/${pkg_name}"

        # Destroy container
        stop_current_container
    }


    ## Function that creates packages in all available containers.
    create_packages() {
        # Start all builds in docker containers
        local container_dir
        for container_dir in "${GPG_GUI_CONTAINER_DIRS[@]}"; do
            create_package "$container_dir"
        done

        printf "\n\n\n"
        echo 'Finished packaging'
        echo "You can find the resulting packages in $GPG_GUI_PKGBUILD_DIR"
    }


    # Exit hooks to stop running containers
    trap stop_current_container EXIT
    trap stop_current_container SIGINT
    trap stop_current_container SIGTERM


    # Import guard
    GPG_GUI_PACKAGES_COMMON_SH='yes'
fi
