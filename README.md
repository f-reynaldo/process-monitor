# Process Memory Monitor

This is a modified version of GNOME Baobab (Disk Usage Analyzer) that has been repurposed to display processes in RAM instead of files on storage.

## Features

- Displays all running processes and their memory usage
- Shows memory usage in a visual chart
- Auto-refreshes every 5 seconds
- Sorts processes by memory usage

## Implementation Details

The implementation involves creating several new files:

1. `baobab-process-scanner.vala` - Scans processes and their memory usage from /proc
2. `baobab-memory-cell.vala` - Displays memory usage in the UI
3. `baobab-process-cell.vala` - Displays process information in the UI
4. `baobab-process-window.vala` - Main window for the process monitor
5. `baobab-process-application.vala` - Application class
6. `process-main.vala` - Entry point

The code reads process information from the `/proc` filesystem, specifically:
- `/proc/[pid]/status` for memory usage (VmRSS)
- `/proc/[pid]/cmdline` for process name

## Building

Due to the complexity of the GNOME build system and the extensive modifications needed, a complete build would require:

1. Installing dependencies:
```bash
sudo apt-get install meson valac libgtk-4-dev libadwaita-1-dev libgee-0.8-dev
```

2. Creating a proper build environment with all necessary UI files and resources

3. Modifying the build system to include the new files

4. run
```
build.sh
```

## Next Steps

To complete this project, you would need to:

1. Create a complete fork of the Baobab repository
2. Modify the build system to include the new files
3. Create or modify the UI files for the process monitor
4. Test and refine the application

## License

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

## Credits

This application is based on GNOME Baobab (Disk Usage Analyzer).

