scripts_dir = meson.current_source_dir()


# Get version of application
version_script = run_command('version.sh')
if version_script.returncode() != 0 or version_script.stdout().strip() == ''
  if version_script.stdout().strip() != ''
    warning('stdout: ' + version_script.stdout().strip())
  endif
  if version_script.stderr().strip() != ''
    warning('stderr: ' + version_script.stderr().strip())
  endif

  warning('Script could not determine version string for application - please build from git or from tarball created by included script')
  gpg_gui_version = '0.0.0-unknown-version'
else
  gpg_gui_version = version_script.stdout().strip()
endif


# Add post install script
meson.add_install_script('meson-postinstall.sh')
