project('gpg-gui', 'vala', 'c')

valac = meson.get_compiler('vala')

# Application names in different styles
reverse_dns = 'com.github.ansgarklein.gpggui'
application_name = 'GPG-Gui'

if get_option('GPG_GUI_RDNS_NAMING')
  binary_name = reverse_dns
else
  binary_name = meson.project_name()
endif

# Source files for binary (will be defined later)
sources = []

# Extra directories for header files
include_dirs = []

# Dependencies of the main binary
dependencies = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk+-3.0'),
  valac.find_library('posix'),
]

gettext_package = reverse_dns
add_project_arguments('-DGETTEXT_PACKAGE=' + gettext_package, language: 'c')

# Enable client-side decorations if desired
if get_option('GPG_GUI_CSD')
  add_project_arguments(['-D', 'GPG_GUI_CSD'], language: 'vala')
endif

subdir('scripts')
subdir('src')
subdir('include')
subdir('vapi')
subdir('data')

# Main target
executable(
  binary_name,
  sources,
  dependencies: dependencies,
  include_directories: include_dirs,
  install: true,
)
