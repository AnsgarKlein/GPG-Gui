# Array of configuration key-value pairs
config_values = [
  ['GETTEXT_PACKAGE',     gettext_package],
  ['GPG_GUI_NAME',        application_name],
  ['GPG_GUI_REVERSE_DNS', reverse_dns],
  ['GPG_GUI_WEBSITE',     'https://github.com/AnsgarKlein/GPG-Gui'],
  ['GPG_GUI_VERSION',     gpg_gui_version],
]

# Create configuration object from configuration array
config_data = configuration_data()
foreach val : config_values
  config_data.set(val[0], val[1])
endforeach

# Generate config.h from template
config_h = configure_file(
  input: 'config.h.in',
  output: 'config.h',
  configuration: config_data
)

# Add path where config.h is generated to list of include directories
include_dirs += include_directories('.')
