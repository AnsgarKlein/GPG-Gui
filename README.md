# GPG-Gui

### Graphical user interface for GnuPG (GPG) file encryption

![Build Status](https://github.com/AnsgarKlein/GPG-Gui/workflows/Build/badge.svg)
![License](https://img.shields.io/github/license/AnsgarKlein/GPG-Gui?color=blue)

<p align="center">
  <img src="misc/gpg-gui.png" alt="example image"/>
</p>


## Purpose

A simple GUI frontend that interacts with the GPG application to encrypt and
decrypt files symmetrically (using passwords not private / public keys).

The GUI provides a convenient way to use GPG, rather than through the terminal,
making it usable for unexperienced users.


## Dependencies

### Dependencies at runtime

+ GnuPG  
  Just the `gpg` or `gpg2` binary
+ GTK+ 3  
  Very likely already installed in your favourite Linux distribution


### Build dependencies

| Dependency                                  | Comment                                                       | Possible package names |
|:-------------------------------------------:|:-------------------------------------------------------------:|:----------------------:|
|Vala Compiler *valac*                        |Likely available in your distributions repositories            |`valac`, `vala`         |
|[Meson](https://mesonbuild.com) build system |Installable via python pip, if distributions version is too old|`meson`                 |
|[Ninja](https://ninja-build.org) build system|Likely available in your distributions repositories            |`ninja-build`           |
|C Compiler: *gcc* or *clang*                 |Install from distributions repositories                        |`gcc`, `clang`          |
|GTK+ 3                          |Library + Header + *.vapi* file<br>(*.vapi* might be included with *valac*) |`gtk+3.0` & `libgtk-3-dev`,<br>`gtk3` & `gtk3-devel`|


## Building

### Setup build directory for out-of-tree build

```bash
meson setup build
```

### Configure (optional)

The build process can optionally be configured with variables. For example:

Change prefix:

```bash
meson configure build -Dprefix=/usr
```

Build optimized build:

```bash
meson configure build -Dbuildtype=release
meson configure build -Doptimization=3
```

Disable client-side decorations

```bash
meson configure build -DGPG_GUI_CSD=false
```

List all currently set build properties:

```bash
meson configure build
```

### Compile

```bash
ninja -C build
```

### Install

```bash
sudo ninja -C build install
```

If you are building a package you can adjust the `DESTDIR`:

```bash
DESTDIR="/path/to/destdir" ninja -C build install
```


## Contributors

+ [Ansgar Klein](https://github.com/AnsgarKlein)
+ [Tinram](https://github.com/Tinram)


## License

GPG-Gui is released under the [GPL v.3](https://www.gnu.org/licenses/gpl-3.0.html).
