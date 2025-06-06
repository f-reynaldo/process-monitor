/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-scanner.vala
 * Original copyright:
 * Copyright (C) 2012  Ryan Lortie <desrt@desrt.ca>
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
        public enum State {
            SCANNING,
            ERROR,
            CHILD_ERROR,
            DONE
        }

        public Results root { get; set; }

        // Used for progress reporting
        public uint64 total_memory { get; private set; }
        public int total_processes { get; private set; }

        public int max_depth { get; protected set; }

        public signal void completed();

        Thread<void*>? thread = null;
        uint process_result_idle = 0;

        AsyncQueue<ResultsArray> results_queue;
        ProcessScanner? self;
        Cancellable cancellable;
        Error? scan_error;

        [Compact]
        class ResultsArray {
            internal Results[] results;
        }

        public class Results : Object {
            // written in the worker thread on creation
            // read from the main thread at any time
            public unowned Results? parent { get; internal set; }
            public string name { get; internal set; }
            public string display_name { get; internal set; }
            internal FileType file_type;

            // written in the worker thread before dispatch
            // read from the main thread only after dispatch
            public uint64 memory_usage { get; internal set; }
            public int pid { get; internal set; }
            public int elements { get; internal set; }
            internal int max_depth;
            internal Error? error;
            internal bool child_error;

            // accessed only by the main thread
            public GLib.ListStore children_list_store { get; construct set; }
            public State state { get; internal set; }

            double _percent;
            public double percent {
                get { return _percent; }
                internal set {
                    _percent = value;

                    notify_property ("fraction");
                }
            }

            public double fraction {
                get {
                    return _percent / 100.0;
                }
            }

            // No need to notify that property when the number of children
            // changes as the whole model won't change once constructed.
            public bool is_empty {
                get { return children_list_store.n_items == 0; }
            }

            construct {
                children_list_store = new ListStore (typeof (Results));
            }

            public Results (int pid, string name, string display_name, uint64 memory_usage, Results? parent_results) {
                parent = parent_results;
                this.name = name;
                this.display_name = display_name;
                if (display_name == null && name != null) {
                    display_name = name;
                }
                if (display_name == null) {
                    display_name = "";
                }
                file_type = FileType.REGULAR; // Using REGULAR as a placeholder
                this.memory_usage = memory_usage;
                this.pid = pid;
                elements = 1;
                error = null;
                child_error = false;
            }

            public Results.empty () {
            }

            public void update_with_child (Results child) {
                memory_usage += child.memory_usage;
                elements     += child.elements;
                max_depth     = int.max (max_depth, child.max_depth + 1);
                child_error  |= child.child_error || (child.error != null);
            }

            public int get_depth () {
                int depth = 1;
                for (var ancestor = parent; ancestor != null; ancestor = ancestor.parent) {
                    depth++;
                }
                return depth;
            }

            public bool is_ancestor (Results? descendant) {
                for (; descendant != null; descendant = descendant.parent) {
                    if (descendant == this)
                        return true;
                }
                return descendant == this;
            }

            public Gtk.TreeListModel create_tree_model () {
                return new Gtk.TreeListModel (children_list_store, false, false, (item) => {
                    var results = item as ProcessScanner.Results;
                    return results == null ? null : results.children_list_store;
                });
            }
        }

        private uint64 parse_memory_usage(string pid_str) {
            try {
                var status_path = "/proc/" + pid_str + "/status";
                var file = File.new_for_path(status_path);
                
                if (!file.query_exists()) {
                    return 0;
                }
                
                var dis = new DataInputStream(file.read());
                string line;
                uint64 memory = 0;
                
                while ((line = dis.read_line()) != null) {
                    if (line.has_prefix("VmRSS:")) {
                        // VmRSS is the resident set size, which is the actual RAM used
                        var parts = line.split_set(" \t");
                        foreach (var part in parts) {
                            if (part.strip() != "" && part.strip() != "VmRSS:") {
                                memory = uint64.parse(part.strip()) * 1024; // Convert from KB to bytes
                                break;
                            }
                        }
                        break;
                    }
                }
                
                return memory;
            } catch (Error e) {
                return 0;
            }
        }
        
        private string get_process_name(string pid_str) {
            try {
                var cmdline_path = "/proc/" + pid_str + "/cmdline";
                var file = File.new_for_path(cmdline_path);
                
                if (!file.query_exists()) {
                    return pid_str;
                }
                
                var dis = new DataInputStream(file.read());
                uint8[] buffer = new uint8[1024];
                long length = dis.read(buffer);
                
                if (length > 0) {
                    string cmdline = (string) buffer;
                    string[] parts = cmdline.split("\0");
                    if (parts.length > 0 && parts[0] != null && parts[0] != "") {
                        string[] cmd_parts = parts[0].split("/");
                        if (cmd_parts.length > 0) {
                            return cmd_parts[cmd_parts.length - 1];
                        }
                        return parts[0];
                    }
                }
                
                // If cmdline is empty, try to get name from status file
                var status_path = "/proc/" + pid_str + "/status";
                file = File.new_for_path(status_path);
                
                if (!file.query_exists()) {
                    return pid_str;
                }
                
                dis = new DataInputStream(file.read());
                string line;
                
                while ((line = dis.read_line()) != null) {
                    if (line.has_prefix("Name:")) {
                        return line.substring(5).strip();
                    }
                }
                
                return pid_str;
            } catch (Error e) {
                return pid_str;
            }
        }

        void scan_processes(Results root_results, ResultsArray results_array) throws Error {
            try {
                var proc_dir = File.new_for_path("/proc");
                var enumerator = proc_dir.enumerate_children("standard::*", 0, null);
                
                FileInfo file_info;
                while ((file_info = enumerator.next_file(null)) != null) {
                    string name = file_info.get_name();
                    
                    // Check if the directory name is a number (PID)
                    if (int.try_parse(name)) {
                        int pid = int.parse(name);
                        string process_name = get_process_name(name);
                        uint64 memory = parse_memory_usage(name);
                        
                        if (memory > 0) {
                            var process_results = new Results(pid, name, process_name, memory, root_results);
                            total_memory += process_results.memory_usage;
                            total_processes++;
                            root_results.update_with_child(process_results);
                            results_array.results += (owned) process_results;
                        }
                    }
                }
            } catch (Error e) {
                throw e;
            }
        }

        void* scan_in_thread() {
            try {
                var array = new ResultsArray();
                var root_results = new Results(0, "Processes", "Processes", 0, null);
                
                scan_processes(root_results, array);
                
                // Calculate percentages for all processes
                foreach (unowned Results process_results in array.results) {
                    if (total_memory > 0) {
                        process_results.percent = 100 * ((double) process_results.memory_usage) / ((double) total_memory);
                    } else {
                        process_results.percent = 0;
                    }
                }
                
                root_results.percent = 100.0;
                array.results += (owned) root_results;
                results_queue.push((owned) array);
            } catch (Error e) {
                // Handle error
            }

            // drop the thread's reference on the Scanner object
            this.self = null;
            return null;
        }

        bool process_results() {
            while (true) {
                var results_array = results_queue.try_pop();

                if (results_array == null) {
                    break;
                }

                foreach (unowned Results results in results_array.results) {
                    if (results.parent != null) {
                        results.parent.children_list_store.insert(0, results);
                    }

                    if (results.child_error) {
                        results.state = State.CHILD_ERROR;
                    } else if (results.error != null) {
                        results.state = State.ERROR;
                    } else {
                        results.state = State.DONE;
                    }

                    if (results.max_depth > max_depth) {
                        max_depth = results.max_depth;
                    }

                    // We reached the root, we're done
                    if (results.parent == null) {
                        this.root = results;
                        scan_error = results.error;
                        completed();
                        return false;
                    }
                }
            }

            return this.self != null;
        }

        public void scan() {
            if (thread != null) {
                return;
            }

            total_memory = 0;
            total_processes = 0;
            max_depth = 0;
            root = null;
            scan_error = null;

            results_queue = new AsyncQueue<ResultsArray>();
            cancellable = new Cancellable();

            // keep a reference to ourselves in a member variable to avoid being finalized while the thread is running
            self = this;

            try {
                thread = new Thread<void*>.try("process-scanner", scan_in_thread);
            } catch (Error e) {
                critical("Failed to create thread: %s", e.message);
                self = null;
                return;
            }

            process_result_idle = Timeout.add(100, process_results);
        }

        public void cancel() {
            if (thread == null) {
                return;
            }

            cancellable.cancel();
            thread.join();
            thread = null;

            if (process_result_idle != 0) {
                Source.remove(process_result_idle);
                process_result_idle = 0;
            }

            self = null;
        }

        ~ProcessScanner() {
            cancel();
        }
    }
}

