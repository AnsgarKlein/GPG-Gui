project('gpg-gui', 'vala', 'c')

valac = meson.get_compiler('vala')

# Main binary to build
binary = meson.project_name()

# Source files for binary
sources = files([
  'src/GPGHandler.vala',
  'src/GPGOperation.vala',
  'src/GPGProcess.vala',
  'src/Helper.vala',
  'src/Main.vala',
  'src/MainWindow.vala',
  'src/ProgressIndicator.vala',
])

# Dependencies of the main binary
dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk+-3.0'),
  valac.find_library('posix'),
]

add_project_arguments('-DGETTEXT_PACKAGE', language: 'c')

# Main target
executable(
  binary,
  sources,
  dependencies: dependencies,
  install: true,
)
