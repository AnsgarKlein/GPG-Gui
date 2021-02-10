#!/bin/sh

###
### This script creates a tarball of the current state of this repository.
### Files listed in .gitignore are ignored. All other files (even files not
### tracked by git!) are included in the resulting tarball.
### The tarball gets saved to the project root.
###


PROJECT_ROOT="$(cd "$(dirname "$0")/.." > /dev/null 2>&1 && pwd)"

# Executing script generates file containing version string
VERSION="$("$(dirname "$0")/version.sh")"
VERSION_TAG='.version_tag'

ARCHIVE="gpg-gui_${VERSION}"


# cd to project root
if ! cd "$PROJECT_ROOT"; then
    echo 'Could not cd to script directory' > /dev/stderr
    exit 1
fi

# Get list of all files in tree that are not ignored via .gitignore
# (except the version tag file)
PROJECT_FILES="$(git ls-files --cached --modified --other --exclude-standard)"
PROJECT_FILES="$(echo "$PROJECT_FILES" | sort --dictionary --unique)"

# Create archive containing only version tag
tar --create -f "${ARCHIVE}.tar" \
--numeric-owner \
--owner 0 \
--group 0 \
"$VERSION_TAG"

# Add every single file separately to archive
echo "$PROJECT_FILES" | while read -r file; do
  # Ignore removed files
  if ! [ -e "$file" ]; then
    continue
  fi

  tar --append -f "${ARCHIVE}.tar" \
  --exclude "${ARCHIVE}.tar" \
  --exclude "${ARCHIVE}.tar.gz" \
  --numeric-owner \
  --owner 0 \
  --group 0 \
  "$file"
done

# Gzip archive
gzip -9 "${ARCHIVE}.tar" --stdout > "${ARCHIVE}.tar.gz"
rm -f "${ARCHIVE}.tar"

# Print name of archive
echo "${ARCHIVE}.tar.gz"
