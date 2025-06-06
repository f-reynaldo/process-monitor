project("process-monitor", ["c", "vala"],
  version: "1.0.0",
  meson_version: ">= 0.50.0",
  license: "GPL2+"
)

gnome = import("gnome")
i18n = import("i18n")

glib = dependency("glib-2.0", version: ">= 2.44")
gio = dependency("gio-2.0", version: ">= 2.44")
gobject = dependency("gobject-2.0", version: ">= 2.44")
gtk = dependency("gtk4", version: ">= 4.0")
libadwaita = dependency("libadwaita-1", version: ">= 1.0")
gee = dependency("gee-0.8", version: ">= 0.8.5")
math = meson.get_compiler("c").find_library("m", required: false)

conf = configuration_data()
conf.set_quoted("GETTEXT_PACKAGE", "process-monitor")
conf.set_quoted("GNOMELOCALEDIR", join_paths(get_option("prefix"), get_option("localedir")))
conf.set_quoted("VERSION", meson.project_version())

configure_file(
  output: "config.h",
  configuration: conf
)

config_h_dir = include_directories(".")

resource_files = files(
  "data/ui/baobab-process-window.ui",
  "data/ui/baobab-chart-menu.ui",
  "data/ui/baobab-chart.css"
)

resources = gnome.compile_resources("process-monitor-resources",
  "data/process-monitor.gresource.xml",
  dependencies: resource_files,
  source_dir: "data",
  c_name: "resources"
)

vapi_sources = [
  "src/config.vapi",
  "/usr/share/vala/vapi/libadwaita-1.vapi"
]

process_monitor_vala_sources = [
  "src/baobab-chart.vala",
  "src/baobab-ringschart.vala",
  "src/baobab-memory-cell.vala",
  "src/baobab-process-application.vala",
  "src/baobab-process-cell.vala",
  "src/baobab-process-scanner.vala",
  "src/baobab-process-window.vala",
  "src/process-main.vala",
  "/usr/share/vala/vapi/libadwaita-1.vapi"
]

process_monitor_sources = [
  vapi_sources,
  process_monitor_vala_sources,
  resources
]

process_monitor_vala_args = [
  "--target-glib", "2.44",
  "--vapidir", meson.current_source_dir() / "src",
  "--pkg", "libadwaita-1",
  "--gresources", meson.current_source_dir() / "data/process-monitor.gresource.xml"
]

process_monitor_c_args = [
  "-include", "config.h"
]

process_monitor_dependencies = [
  glib,
  gio,
  gobject,
  gtk,
  libadwaita,
  math,
  gee
]

executable("process-monitor", process_monitor_sources,
  include_directories: config_h_dir,
  vala_args: process_monitor_vala_args,
  c_args: process_monitor_c_args,
  dependencies: process_monitor_dependencies,
  export_dynamic: true,
  install: true
)


