#!/bin/sh

###
### This script returns the version string for the upstream
### application (package versions might be different).
###
### This script is a helper script for the Meson build system.
### It is automatically run in the build process in order to determine
### the version string for the current build.
###
### This script uses git tags to determine the version string
### for the project and prints it to stdout. It also creates a
### .version_tag file in the project root containing the version.
### If no .git folder is found in project root the content of the
### previously created .version_tag file is printed.
###


PROJECT_ROOT="$(cd "$(dirname "$0")/.." > /dev/null 2>&1 && pwd)"
VERSION_TAG_FILE='.version_tag'


# cd to project root
if ! cd "$PROJECT_ROOT"; then
    echo 'Could not cd to project root' > /dev/stderr
    exit 1
fi


if [ -d '.git' ]; then
    # Run git status
    git status > /dev/null 2>&1

    # Get version from git tags
    GIT_DESCRIBE="git describe --tags --long --dirty --broken"
    GIT_DESCRIBE="$GIT_DESCRIBE --match   v[0-9]*.[0-9]*.[0-9]*"
    GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*[!0-9]*.*.*"
    GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*.*[!0-9]*.*"
    GIT_DESCRIBE="$GIT_DESCRIBE --exclude v*.*.*[!0-9]*"
    if ! VERSION="$($GIT_DESCRIBE)"; then
        echo 'Could not determine valid version string' > /dev/stderr
        exit 1
    fi

    # Remove 'v' prefix from version string
    VERSION="$(echo "$VERSION" | sed 's/^v//')"

    # Error if version string is empty
    if [ -z "$VERSION" ]; then
        echo 'Could not determine valid version string' > /dev/stderr
        exit 1
    fi

    # Hardcode version to file in project root, which can be included in
    # source tarball. This makes it possible to build package from a tarball
    # with a correct version without having to include the whole .git directory
    # in the tarball.
    echo "$VERSION" > "$VERSION_TAG_FILE"

    echo "$VERSION"
else
    # There is no git repository so use hardcoded version string
    if ! [ -e "$VERSION_TAG_FILE" ]; then
        echo 'Could not determine valid version string' > /dev/stderr
        exit 1
    fi

    cat "$VERSION_TAG_FILE"
fi
