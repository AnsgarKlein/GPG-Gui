#!/bin/bash

##
## This script builds a debian package based on the current
## project sources.
## There are scripts to use this script inside a docker container but
## if you are running the correct operating system with all necessary
## dependencies this script should work in your environment as well.
##


set -e


# Dont run as root
if [[ "$(whoami)" = 'root' || "$UID" -eq '0' ]]; then
    echo 'Dont run as root!' > /dev/stderr
    exit 1
fi


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="$(cd "${SCRIPT_DIR}/../build" && pwd)"

# Version of the resulting package
GPG_GUI_VERSION="$("${SCRIPT_DIR}/version.sh")"

# Architecture of the resulting package
GPG_GUI_ARCH="$("${SCRIPT_DIR}/arch.sh")"

# Dependencies in control format
GPG_GUI_DEPS="$("${SCRIPT_DIR}/dependencies.sh")"

# Path to the resulting package file
PKG_FILE="${OUTPUT_DIR}/$("${SCRIPT_DIR}/package-name.sh")"


cd "$PROJECT_ROOT"


# Create package structure
echo -e '\n\n########## ########## ########## Creating package structure ...'
PKG_ROOT="${PROJECT_ROOT}/build-pkgroot"

echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "PACKAGE_ROOT: $PKG_ROOT"
echo "PACKAGE_FILE: $PKG_FILE"

mkdir "${PKG_ROOT}"
mkdir "${PKG_ROOT}/DEBIAN"

cat > "${PKG_ROOT}/DEBIAN/control" << EOF
Package: gpg-gui
Architecture: ${GPG_GUI_ARCH}
Version: ${GPG_GUI_VERSION}
Priority: optional
${GPG_GUI_DEPS}
Maintainer: upstream
Homepage: https://github.com/AnsgarKlein/GPG-Gui
Description: Simple GUI front-end that interacts with the GPG application to
 encrypt and decrypt files symmetrically (using passwords not private / public
 keys).
 The GUI provides a convenient way to use GPG, rather than through the
 terminal, making it usable for unexperienced users.
EOF

mkdir -p "${PKG_ROOT}/usr/share/doc/gpg-gui"
cat > "${PKG_ROOT}/usr/share/doc/gpg-gui/copyright" << EOF
Files: *
Copyright:
 Copyright (C) $(date +%Y) upstream
License: GPL-3+
EOF


# Compile code
echo -e '\n\n########## ########## ########## Compiling code ...'
meson setup build > /dev/null
meson configure build -Dbuildtype=release
meson configure build -Doptimization=3
meson configure build -Dprefix=/usr
meson configure build -DGPG_GUI_CSD=true
meson configure build -DGPG_GUI_RDNS_NAMING=false
meson configure build
ninja -C build


# Install to package structure
echo -e '\n\n########## ########## ########## Installing code to package structure ...'
DESTDIR="$PKG_ROOT" meson install -C build


# Build package
echo -e '\n\n########## ########## ########## Building package ...'
strip --strip-debug --strip-unneeded "$PKG_ROOT/usr/bin/gpg-gui"

bash -c "cd \"$PKG_ROOT\" && find \"$PKG_ROOT\" -type f ! -regex '.*?DEBIAN.*' -printf '%P\0' | xargs -0 md5sum" > "${PKG_ROOT}/DEBIAN/md5sums"

fakeroot dpkg-deb --build --debug \
-Z xz \
-z 9 \
--root-owner-group \
"$PKG_ROOT" \
"$PKG_FILE"


# Print package information
echo -e '\n\n########## ########## ########## Printing package information ...'
dpkg-deb --info "$PKG_FILE"
echo ''
echo 'Content:'
dpkg-deb --fsys-tarfile "$PKG_FILE" | tar -tf - | grep -v '/$'


# Pre-test package
echo -e '\n\n########## ########## ########## Pre-testing package ...'
lintian --check \
--suppress-tags debian-changelog-file-missing \
--suppress-tags maintainer-address-missing \
"$PKG_FILE"


# Install package
echo -e '\n\n########## ########## ########## Installing package ...'
sudo dpkg -i "$PKG_FILE"


# Post-test package
echo -e '\n\n########## ########## ########## Post-testing package ...'
EXPECTED_FILES=(
  '/usr/bin/gpg-gui'
  '/usr/share/applications/gpg-gui.desktop'
  '/usr/share/icons/hicolor/64x64/apps/gpg-gui.png'
  '/usr/share/icons/hicolor/scalable/apps/gpg-gui.svg'
)
for file in "${EXPECTED_FILES[@]}"; do
  if ! [[ -e /usr/bin/gpg-gui ]]; then
    echo "Error - missing file '$file'"
    exit 1
  fi
done
echo 'Seems okay ...'
