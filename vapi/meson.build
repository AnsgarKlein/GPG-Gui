vapi_dir = meson.current_source_dir()

dependencies += valac.find_library('config', dirs: vapi_dir)

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')
