desktop = 'gpg-gui.desktop'

desktop_config = configuration_data()
desktop_config.set('icon', 'application-x-executable')
desktop_config.set('binary', binary)

configure_file(
  input: desktop + '.in',
  output: desktop,
  configuration: desktop_config,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)
