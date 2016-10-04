
# GPG-Gui

### GUI interface to GnuPG (GPG)


## Purpose

A simple GUI executable that interfaces with the GPG application to encrypt and decrypt files via GPG.

The GUI provides a convenient way to use GPG, rather than through the command line (with the complicated range of GPG switches available).

Symmetric encryption is used: a password is used, not a private key file.

The GPG cipher, hash algorithm, and hash strengthening can be changed in the GUI.


## OS Support

+ Linux

Windows - untried, but will be possible with effort. A Vala installer is available.


## Requirements

+ GPG (gnupg)


## Build Requirements

+ Vala (valac)
+ GTK3 (libgtk-3-dev)


## Build

### Linux

    make


## License

GPG-Gui is released under the [GPL v.3](https://www.gnu.org/licenses/gpl-3.0.html).
