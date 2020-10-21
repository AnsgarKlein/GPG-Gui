
# GPG-Gui

### GUI interface for GnuPG (GPG) file encryption.

![example image](misc/gpg-gui.png)


## Purpose

A simple GUI frontend that interacts with the GPG application to encrypt and decrypt files.

The GUI provides a convenient way to use GPG, rather than through the terminal, along with encryption-strengthening switches.

Symmetric encryption is used: a password, not a private key file.

The GPG cipher, hash algorithm, and hash strengthening can be changed in the GUI.


## OS Support

+ Linux

Windows - A Vala installer is available.  Depending on version, the Vala code requires updating.


## Requirements

+ GPG (gnupg)


## Build Requirements

+ Vala (valac)
+ GTK3 (libgtk-3-dev)


## Build

```bash
    make
```


## Credits

Ansgar Klein, original developer.


## License

GPG-Gui is released under the [GPL v.3](https://www.gnu.org/licenses/gpl-3.0.html).
