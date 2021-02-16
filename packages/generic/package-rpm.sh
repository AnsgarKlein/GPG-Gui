#!/bin/bash

##
## This script builds a rpm package based on the current
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

# Revision (Release) of the resulting package
GPG_GUI_REVISION="$("${SCRIPT_DIR}/revision.sh")"

# Architecture of the resulting package
GPG_GUI_ARCH="$("${SCRIPT_DIR}/arch.sh")"

# Dependencies in rpm spec format
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

# Create directories
mkdir "${PKG_ROOT}"
mkdir "${PKG_ROOT}/"{BUILD,RPMS,SOURCES,SPECS,SRPMS}


# Create package
echo -e '\n\n########## ########## ########## Creating package -> rpmbuild ...'

# Create specs file
cat > "${PKG_ROOT}/SPECS/gpg-gui.spec" << EOF
Name:           gpg-gui
Version:        ${GPG_GUI_VERSION}
Release:        ${GPG_GUI_REVISION}
${GPG_GUI_DEPS}

License:        GPLv3+
Packager:       upstream
URL:            https://github.com/AnsgarKlein/GPG-Gui

Summary:        Simple GUI front-end for gnupg

%description
Simple GUI front-end that interacts with the GPG application to encrypt
and decrypt files symmetrically (using passwords not private / public keys).
The GUI provides a convenient way to use GPG, rather than through the
terminal, making it usable for unexperienced users.


%prep
set +x
set -e
echo -e '\n\n########## ########## ########## Creating package -> rpmbuild: prep ...'
echo "topdir:       %{_topdir}"
echo "sourcedir:    %{_sourcedir}"
echo "builddir:     %{_builddir}"
echo "buildrootdir: %{_buildrootdir}"
echo "buildroot:    %{buildroot}"
echo "rpmdir:       %{_rpmdir}"
echo ''


%build
set +x
set -e
echo -e '\n\n########## ########## ########## Creating package -> rpmbuild: build ...'
meson setup \
 -Dbuildtype=release \
 -Doptimization=3 \
 -Dprefix=/usr \
 -DGPG_GUI_CSD=true \
 -DGPG_GUI_RDNS_NAMING=false \
 "%{_builddir}" \
 "$PROJECT_ROOT"
ninja -C "%{_builddir}"
echo ''


%install
set +x
set -e
echo -e '\n\n########## ########## ########## Creating package -> rpmbuild: install ...'
# Install to destdir
DESTDIR="%{buildroot}" ninja -C "%{_builddir}" install

# Strip binary
strip --strip-debug --strip-unneeded "%{buildroot}/usr/bin/gpg-gui"

# Generate file list
(cd "%{buildroot}" && find . -type f | cut -c 2-) > "${PKG_ROOT}/file-list"
echo ''

# Copy documentation files
cp "${PROJECT_ROOT}/README.md" "%{_builddir}/"
cp "${PROJECT_ROOT}/COPYING" "%{_builddir}/"

%files -f $PKG_ROOT/file-list
%doc README.md
%doc COPYING
EOF

rpmbuild \
 -bb \
 --define "_topdir $PKG_ROOT" \
 --define "_build_id_links none" \
 --noclean \
 "${PKG_ROOT}/SPECS/gpg-gui.spec"
cp "${PKG_ROOT}/RPMS/${GPG_GUI_ARCH}/$(basename "$PKG_FILE")" "$PKG_FILE"


# Print package information
echo -e '\n\n########## ########## ########## Printing package information ...'
rpm --query --info --package "$PKG_FILE"
echo ''
echo 'Content:'
rpm --query --list --package "$PKG_FILE"


# Pre-test package
echo -e '\n\n########## ########## ########## Pre-testing package ...'
cat > '/tmp/rpmlint.config' << EOF
addFilter('spelling-error')
addFilter('no-changelogname-tag')
EOF

rpmlint \
-f '/tmp/rpmlint.config' \
"$PKG_FILE"


# Install package
echo -e '\n\n########## ########## ########## Installing package ...'
sudo rpm -i --test "$PKG_FILE"
sudo rpm -i --verbose "$PKG_FILE"
sudo rpm --verify "$PKG_FILE"


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
