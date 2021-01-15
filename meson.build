project('gpg-gui', 'vala', 'c', meson_version: '>=0.50')

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
subdir('data')
subdir('include')
subdir('vapi')

# Print summary of build configuration
if meson.version().version_compare('>=0.53')
  summary({
    'prefix':  get_option('prefix'),
    'datadir': get_option('datadir'),
    'bindir':  get_option('bindir'),
    }, section: 'Directories'
  )

  summary({
    'buildtype':    get_option('buildtype'),
    'debug':        get_option('debug'),
    'optimization': get_option('optimization'),
    'unity':        get_option('unity'),
    }, section: 'Build configuration'
  )

  summary({
    'GPG_GUI_CSD':         get_option('GPG_GUI_CSD'),
    'GPG_GUI_RDNS_NAMING': get_option('GPG_GUI_CSD'),
    'application verson':  gpg_gui_version,
    }, section: 'Application configuration'
  )
else
  message('Directories')
  message('prefix:  @0@'.format(get_option('prefix')))
  message('datadir: @0@'.format(get_option('datadir')))
  message('bindir:  @0@'.format(get_option('bindir')))
  message('')
  message('Build configuration')
  message('buildtype:    @0@'.format(get_option('buildtype')))
  message('debug:        @0@'.format(get_option('debug')))
  message('optimization: @0@'.format(get_option('optimization')))
  message('unity:        @0@'.format(get_option('unity')))
  message('')
  message('Application configuration')
  message('GPG_GUI_CSD:         @0@'.format(get_option('GPG_GUI_CSD')))
  message('GPG_GUI_RDNS_NAMING: @0@'.format(get_option('GPG_GUI_RDNS_NAMING')))
  message('application version: @0@'.format(gpg_gui_version))
endif

# Meson versions "0.52< version <0.56" will print warnings when using features
# that were introduced in Meson versions older than the projects required Meson
# version (specified in project() function) EVEN IF those features were wrapped
# in a version comparison conditional and would not be used unless the installed
# Meson version supported them. This is Meson bug #7590.
# Remove this block once Meson 0.56 is a hard requirement (-> project()).
if meson.version().version_compare('>0.53') and meson.version().version_compare('<0.56')
  warning('Please ignore warnings about using features introduced in newer versions than this project is targeting.')
  warning('Those messages are because of Meson bug #7590, which is fixed in Meson 0.56.')
  warning('You can get rid of this message by using a newer version of Meson.')
endif

# Main target
executable(
  binary_name,
  sources,
  dependencies: dependencies,
  include_directories: include_dirs,
  install: true,
)
