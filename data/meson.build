# Select name for desktop file based on binary name.
# This could be in reverse-dns style notation.
desktop = binary_name + '.desktop'

desktop_config = configuration_data()
desktop_config.set('application_name', application_name)
desktop_config.set('icon_name',        'application-x-executable')
desktop_config.set('binary_name',      binary_name)

configure_file(
  input: 'gpg-gui.desktop.in',
  output: desktop,
  configuration: desktop_config,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)
