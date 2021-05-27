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


# If we want a unity build we have to create a vala
# unity source file since meson will otherwise try
# to create unity source file from generated c sources
# which will fail.
if meson.is_unity()
    # Create unity source from all sources
    unity_source = custom_target(
      'generate_unity',
      input: sources,
      output: 'unity.vala',
      command: [
        join_paths(meson.current_source_dir(), 'gen_unity_source.sh'),
        '@INPUT@', '--output', '@OUTPUT@'
      ],
    )

    # Overwrite variable with unity source
    sources = unity_source
endif


# Add post install script
meson.add_install_script('meson-postinstall.sh')
