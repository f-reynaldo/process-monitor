/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-window.vala
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

    [GtkTemplate (ui = "/org/gnome/baobab/ui/baobab-process-window.ui")]
    public class ProcessWindow : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.EventControllerFocus focus_controller;
        [GtkChild]
        private unowned Gtk.Widget home_page;
        [GtkChild]
        private unowned Gtk.Widget result_page;
        [GtkChild]
        private unowned Gtk.ColumnView columnview;
        [GtkChild]
        private unowned Gtk.SingleSelection columnview_selection;
        [GtkChild]
        private unowned Chart chart;

        private ProcessScanner scanner;
        private Gtk.TreeListModel tree_model;
        private Gtk.SortListModel sort_model;
        private Gtk.StringList chart_model;

        private uint refresh_timeout_id = 0;

        construct {
            scanner = new ProcessScanner ();
            scanner.completed.connect (on_scanner_completed);

            setup_column_view ();
            setup_chart ();

            // Start scanning processes
            start_scan ();

            // Set up a timer to refresh the process list every 5 seconds
            refresh_timeout_id = Timeout.add_seconds (5, () => {
                start_scan ();
                return true;
            });
        }

        ~ProcessWindow () {
            if (refresh_timeout_id > 0) {
                Source.remove (refresh_timeout_id);
            }
        }

        private void setup_column_view () {
            var name_factory = new Gtk.SignalListItemFactory();
            name_factory.setup.connect((factory, list_item) => {
                var cell = new ProcessCell();
                list_item.set_child(cell);
            });
            
            name_factory.bind.connect((factory, list_item) => {
                var cell = list_item.get_child() as ProcessCell;
                var tree_list_row = list_item.get_item() as Gtk.TreeListRow;
                var results = tree_list_row != null ? tree_list_row.get_item() as ProcessScanner.Results : null;
                if (results != null) {
                    cell.update(results);
                }
            });
            
            var name_column = new Gtk.ColumnViewColumn(_("Process"), name_factory);
            name_column.expand = true;
            columnview.append_column(name_column);

            var memory_factory = new Gtk.SignalListItemFactory();
            memory_factory.setup.connect((factory, list_item) => {
                var cell = new MemoryCell();
                list_item.set_child(cell);
            });
            
            memory_factory.bind.connect((factory, list_item) => {
                var cell = list_item.get_child() as MemoryCell;
                var tree_list_row = list_item.get_item() as Gtk.TreeListRow;
                var results = tree_list_row != null ? tree_list_row.get_item() as ProcessScanner.Results : null;
                if (results != null) {
                    cell.update(results);
                }
            });
            
            var memory_column = new Gtk.ColumnViewColumn(_("Memory"), memory_factory);
            columnview.append_column(memory_column);

            var sorter = new Gtk.TreeListRowSorter(new ProcessMemorySorter());
            sort_model = new Gtk.SortListModel(null, sorter);
            columnview_selection.set_model(sort_model);
        }

        private void setup_chart() {
            chart_model = new Gtk.StringList(null);
            chart.model = chart_model;
        }

        private void start_scan() {
            scanner.cancel();
            scanner.scan();
            // Use stack instead of NavigationView
            var stack = home_page.get_parent() as Gtk.Stack;
            if (stack != null) {
                stack.set_visible_child(home_page);
            }
        }

        private void on_scanner_completed() {
            if (scanner.root == null) {
                return;
            }

            tree_model = scanner.root.create_tree_model();
            sort_model.set_model(tree_model);

            // Update chart with top processes
            chart_model.splice(0, chart_model.get_n_items(), null);
            
            // Get top processes by memory usage
            var processes = new Gee.ArrayList<ProcessScanner.Results>();
            TreeIter iter;
            if (scanner.root.children_list_store.get_iter_first(out iter)) {
                do {
                    Value val;
                    scanner.root.children_list_store.get_value(iter, 0, out val);
                    Results? results = val.get_object() as Results;
                    if (results != null) {
                        processes.add(results);
                    }
                } while (scanner.root.children_list_store.iter_next(ref iter));
            }
            
            // Sort by memory usage
            processes.sort((a, b) => {
                if (a.memory_usage > b.memory_usage) {
                    return -1;
                } else if (a.memory_usage < b.memory_usage) {
                    return 1;
                } else {
                    return 0;
                }
            });
            
            // Add top processes to chart
            int count = 0;
            foreach (var results in processes) {
                if (count >= 10) {
                    break;
                }
                chart_model.append(results.display_name);
                count++;
            }

            // Use stack instead of NavigationView
            var stack = result_page.get_parent() as Gtk.Stack;
            if (stack != null) {
                stack.set_visible_child(result_page);
            }
        }

        [GtkCallback]
        private void on_scan_button_clicked() {
            start_scan();
        }

        [GtkCallback]
        private void on_stop_button_clicked() {
            scanner.cancel();
        }
    }

    private class ProcessMemorySorter : Gtk.Sorter {
        public override Gtk.Ordering compare(Object? a, Object? b) {
            var row_a = a as Gtk.TreeListRow;
            var row_b = b as Gtk.TreeListRow;

            if (row_a == null || row_b == null) {
                return Gtk.Ordering.EQUAL;
            }

            var results_a = row_a.get_item() as ProcessScanner.Results;
            var results_b = row_b.get_item() as ProcessScanner.Results;

            if (results_a == null || results_b == null) {
                return Gtk.Ordering.EQUAL;
            }

            if (results_a.memory_usage > results_b.memory_usage) {
                return Gtk.Ordering.SMALLER;
            } else if (results_a.memory_usage < results_b.memory_usage) {
                return Gtk.Ordering.LARGER;
            } else {
                return Gtk.Ordering.EQUAL;
            }
        }

        public override Gtk.SorterOrder get_order() {
            return Gtk.SorterOrder.PARTIAL;
        }
    }
}

