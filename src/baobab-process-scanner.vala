/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-scanner.vala
 * Original copyright:
 * Copyright (C) 2012  Paolo Borelli <pborelli@gnome.org>
 * Copyright (C) 2012  Stefano Facchini <stefano.facchini@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

namespace Baobab {

    public class ProcessScanner : Object {
        public class Results : Object {
            public string display_name { get; set; }
            public string process_name { get; set; }
            public int pid { get; set; }
            public uint64 memory_usage { get; set; }
            public double percent { get; set; }
            public Gtk.ListStore children_list_store { get; set; }

            public bool is_empty {
                get { 
                    bool empty = true;
                    Gtk.TreeIter iter;
                    if (children_list_store.get_iter_first(out iter)) {
                        empty = false;
                    }
                    return empty;
                }
            }

            public Results (string display_name, string process_name, int pid, uint64 memory_usage) {
                this.display_name = display_name;
                this.process_name = process_name;
                this.pid = pid;
                this.memory_usage = memory_usage;
                this.percent = 0.0;
                this.children_list_store = new Gtk.ListStore (1, typeof (Results));
            }

            public Gtk.TreeListModel create_tree_model () {
                return new Gtk.TreeListModel (children_list_store, false, true, (item) => {
                    var results = item as ProcessScanner.Results;
                    if (results != null && !results.is_empty) {
                        return results.children_list_store;
                    }
                    return null;
                });
            }
        }

        public Results? root { get; private set; }
        public bool is_active { get; private set; }
        public bool has_aborted { get; private set; }

        private Cancellable cancellable;

        public signal void completed ();
        public signal void changed ();

        public ProcessScanner () {
            cancellable = new Cancellable ();
        }

        public void scan () {
            if (is_active) {
                return;
            }

            is_active = true;
            has_aborted = false;
            cancellable.reset ();

            new Thread<void*> (null, () => {
                scan_processes ();
                return null;
            });
        }

        public void cancel () {
            if (!is_active) {
                return;
            }

            cancellable.cancel ();
            has_aborted = true;
        }

        private void scan_processes () {
            root = new Results ("All Processes", "all", 0, 0);

            try {
                var dir = Dir.open ("/proc");
                string? name;

                while ((name = dir.read_name ()) != null) {
                    if (cancellable.is_cancelled ()) {
                        break;
                    }

                    // Check if the directory name is a number (PID)
                    if (name[0].isdigit ()) {
                        int pid = int.parse (name);
                        scan_process (pid);
                    }
                }
            } catch (FileError e) {
                warning ("Error opening /proc: %s", e.message);
            }

            // Calculate percentages
            uint64 total_memory = root.memory_usage;
            if (total_memory > 0) {
                Gtk.TreeIter iter;
                if (root.children_list_store.get_iter_first(out iter)) {
                    do {
                        Value val;
                        root.children_list_store.get_value(iter, 0, out val);
                        ProcessScanner.Results? results = val.get_object() as ProcessScanner.Results;
                        if (results != null) {
                            results.percent = (double)results.memory_usage / total_memory * 100.0;
                        }
                    } while (root.children_list_store.iter_next(ref iter));
                }
            }

            is_active = false;
            Idle.add (() => {
                completed ();
                return false;
            });
        }

        private void scan_process (int pid) {
            try {
                string status_path = "/proc/%d/status".printf (pid);
                string cmdline_path = "/proc/%d/cmdline".printf (pid);

                // Read process name and memory usage from status file
                string process_name = "";
                uint64 memory_usage = 0;

                var status_file = File.new_for_path (status_path);
                var dis = new DataInputStream (status_file.read ());
                string line;

                while ((line = dis.read_line ()) != null) {
                    if (line.has_prefix ("Name:")) {
                        process_name = line.substring (5).strip ();
                    } else if (line.has_prefix ("VmRSS:")) {
                        string mem_str = line.substring (6).strip ();
                        string[] parts = mem_str.split (" ");
                        if (parts.length >= 2) {
                            memory_usage = uint64.parse (parts[0]) * 1024; // Convert from KB to bytes
                        }
                        break;
                    }
                }

                // Read command line for a better display name
                string display_name = process_name;
                try {
                    var cmdline_file = File.new_for_path (cmdline_path);
                    var cmdline_dis = new DataInputStream (cmdline_file.read ());
                    uint8[] cmdline_data = new uint8[1024];
                    size_t length;

                    if (cmdline_dis.read_all (cmdline_data, out length)) {
                        string cmdline = (string) cmdline_data;
                        if (cmdline.length > 0) {
                            // Extract the executable name from the path
                            string[] parts = cmdline.split ("/");
                            if (parts.length > 0) {
                                string exe_name = parts[parts.length - 1];
                                if (exe_name.length > 0) {
                                    display_name = exe_name;
                                }
                            }
                        }
                    }
                } catch (Error e) {
                    // Ignore errors reading cmdline
                }

                // Add the process to the root
                if (memory_usage > 0) {
                    var results = new Results (display_name, process_name, pid, memory_usage);
                    Gtk.TreeIter iter;
                    root.children_list_store.append(out iter);
                    root.children_list_store.set(iter, 0, results);
                    root.memory_usage += memory_usage;
                }
            } catch (Error e) {
                // Ignore errors for processes we can't access
            }
        }
    }
}

