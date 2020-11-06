project('GPG-Gui', 'vala', 'c')

sources = files([
    'src/GPGHandler.vala',
    'src/GPGOperationType.vala',
    'src/GPGProcess.vala',
    'src/Helper.vala',
    'src/Main.vala',
    'src/MainFrame.vala',
])

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
]

add_project_arguments('-DGETTEXT_PACKAGE', language: 'c')

executable('gpg-gui', sources, dependencies: dependencies, install: true)
