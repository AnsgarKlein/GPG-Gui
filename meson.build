project('GPG-Gui', 'vala', 'c')

sources = files([
    'src/GPGHandler.vala',
    'src/GPGOperation.vala',
    'src/GPGProcess.vala',
    'src/Helper.vala',
    'src/Main.vala',
    'src/MainWindow.vala',
    'src/ProgressIndicator.vala',
])

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    meson.get_compiler('vala').find_library('posix'),
]

add_project_arguments('-DGETTEXT_PACKAGE', language: 'c')

executable('gpg-gui', sources, dependencies: dependencies, install: true)
