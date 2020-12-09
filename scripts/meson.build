scripts_dir = meson.current_source_dir()

# Get version of application
version_script = run_command('git-revision.sh')
if version_script.returncode() != 0
  warning('Could not determine application version via current git revision')
  warning('Using placeholder version string')
  gpg_gui_version = '0.0.0-unknown-version'
else
  gpg_gui_version = version_script.stdout().strip()
endif
