
# GPG-Gui

### GUI interface for GnuPG (GPG) file encryption.

![example image](misc/gpg-gui.png)


## Purpose

A simple GUI frontend that interacts with the GPG application to encrypt and
decrypt files.

The GUI provides a convenient way to use GPG, rather than through the terminal,
along with encryption-strengthening switches.

Symmetric encryption is used: a password, not a private key file.

The GPG cipher, hash algorithm, and hash strengthening can be changed in the GUI.


## OS Support

+ Linux

+ Windows  
  Not tested. If you can get all requirements to work (vala, gtk, ...)
  it should work too.


## Requirements

+ GPG  
  (just the gpg binary)
  
+ GTK+ 3  
  (Probably already installed on your linux machine)


## Build Requirements

+ Vala Compiler (valac)

+ GTK+ 3  
  (including its development files)


## Build

```bash
    make
```


## Credits

Ansgar Klein, original developer.


## License

GPG-Gui is released under the [GPL v.3](https://www.gnu.org/licenses/gpl-3.0.html).
