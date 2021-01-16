#!/bin/sh

###
### This script is a helper script for the Meson build system.
### It is automatically run in order to finish the install procedure.
###


if [ -n "$DESTDIR" ] && [ -n "$MESON_INSTALL_PREFIX" ]; then
    # Installing with DESTDIR means we are probably
    # building a package and this script is not needed
    exit 0
fi


# If MESON_INSTALL_PREFIX is not set something is wrong with the
# build environment. (Probably not run via meson)
if [ -z "$MESON_INSTALL_PREFIX" ] || [ ! -d "$MESON_INSTALL_PREFIX" ]; then
    echo "MESON_INSTALL_PREFIX is not set or invalid!" > /dev/stderr
    exit 1
fi

DATADIR="${MESON_INSTALL_PREFIX}/share"

if [ ! -d "$DATADIR" ]; then
    echo "DATADIR \"${DATADIR}\" does not exist!" > /dev/stderr
    exit 1
fi

DESKTOP_DIR="${DATADIR}/applications"

if [ ! -d "$DESKTOP_DIR" ]; then
    echo "Directory \"${DESKTOP_DIR}\" does not exist!" > /dev/stderr
    exit 1
fi

ICONS_DIR="${DATADIR}/icons/hicolor"

if [ ! -d "$ICONS_DIR" ]; then
    echo "Directory \"${ICONS_DIR}\" does not exist!" > /dev/stderr
    exit 1
fi


# If update-desktop-database program does not exist on this system
# it is probably safe to ignore it.
if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database -q "$DESKTOP_DIR"
fi

# If gtk-update-icon-cache program does not exist on this system
# it is probably safe to ignore it.
if command -v gtk-update-icon-cache > /dev/null 2>&1; then
    gtk-update-icon-cache -q "$ICONS_DIR"
fi
