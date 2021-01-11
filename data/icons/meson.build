# Select icon name based on binary name.
# This could be in reverse-dns style notation.
icon_name = binary_name

# Install multiple scaled png icons
foreach i : [ '16', '24', '32', '48', '64', '128' ]
  install_data(
    'gpg-gui_' + i + '.png',
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
    rename: icon_name + '.png',
  )
endforeach

# Install scalable svg icon
install_data(
  'gpg-gui.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps'),
  rename: icon_name + '.svg'
)

# Install scalable symbolic icon
install_data(
  'gpg-gui-symbolic.svg',
  install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'symbolic', 'apps'),
  rename: icon_name + '-symbolic.svg'
)
