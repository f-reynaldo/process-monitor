project(
  'process-monitor', ['c', 'vala'],
  version: '1.0.0',
  meson_version: '>= 0.50.0',
  license: 'GPL2+'
)

# Import gnome module
gnome = import('gnome')

# Dependencies
glib_dep = dependency('glib-2.0', version: '>= 2.44')
gio_dep = dependency('gio-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4')
adwaita_dep = dependency('libadwaita-1')
gee_dep = dependency('gee-0.8')
math_dep = meson.get_compiler('c').find_library('m', required: false)
pangocairo_dep = dependency('pangocairo')

# Configuration
conf = configuration_data()
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))

configure_file(
  output: 'config.h',
  configuration: conf
)

# Resources
resource_files = files(
  'data/ui/baobab-process-window.ui',
  'data/ui/baobab-chart-menu.ui',
  'data/ui/baobab-chart.css'
)

resources = gnome.compile_resources(
  'process-monitor-resources',
  'data/process-monitor.gresource.xml',
  source_dir: 'data',
  dependencies: resource_files
)

# VAPI sources
vapi_sources = [
  'src/config.vapi',
  'builddir/config.h',
  '/usr/share/vala-0.56/vapi/gio-2.0.vapi' # Adicionado explicitamente para garantir que o Vala encontre o VAPI do gio-2.0
]

# Vala sources
process_monitor_vala_sources = [
  'src/baobab-chart.vala',
  'src/baobab-ringschart.vala',
  'src/baobab-memory-cell.vala',
  'src/baobab-process-application.vala',
  'src/baobab-process-cell.vala',
  'src/baobab-process-scanner.vala',
  'src/baobab-process-window.vala',
  'src/process-main.vala'
]

# Vala arguments
process_monitor_vala_args = [
  '--target-glib', '2.44',
  '--vapidir', meson.current_source_dir() / 'src',
  '--vapidir', '/usr/share/vala-0.56/vapi',
  '--gresources', meson.current_source_dir() / 'data/process-monitor.gresource.xml',
  '--pkg', 'libadwaita-1',
  '--pkg', 'gio-2.0' # Adicionado para garantir que o Vala encontre o VAPI do gio-2.0
]

# Dependencies list
process_monitor_deps = [
  glib_dep,
  gio_dep,
  gobject_dep,
  gtk_dep,
  adwaita_dep,
  gee_dep,
  math_dep,
  pangocairo_dep,
]

# Executable
executable('process-monitor',
  vapi_sources + process_monitor_vala_sources + [resources],
  dependencies: process_monitor_deps,
  vala_args: process_monitor_vala_args,
  install: true
)


