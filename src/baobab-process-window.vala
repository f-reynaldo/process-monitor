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
        private unowned Adw.NavigationView nav_view;
        [GtkChild]
        private unowned Gtk.Widget home_page;
        [GtkChild]
        private unowned Gtk.Widget result_page;
        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;
        [GtkChild]
        private unowned Adw.Banner banner;
        [GtkChild]
        private unowned Gtk.ColumnView columnview;
        [GtkChild]
        private unowned Gtk.SingleSelection columnview_selection;
        [GtkChild]
        private unowned Chart chart;

        private ProcessScanner scanner;
        private Gtk.TreeListModel tree_model;
        private Gtk.SortListModel sort_model;
        private Gtk.ColumnViewColumn name_column;
        private Gtk.ColumnViewColumn memory_column;

        private Gtk.StringList chart_model;
        private Gtk.NoSelection chart_selection;

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
            name_column = new Gtk.ColumnViewColumn (_("Process"));
            name_column.expand = true;
            name_column.factory = new Gtk.SignalListItemFactory ();
            name_column.factory.setup.connect ((factory, list_item) => {
                var cell = new ProcessCell ();
                list_item.child = cell;
            });
            name_column.factory.bind.connect ((factory, list_item) => {
                var cell = list_item.child as ProcessCell;
                var tree_list_row = list_item.item as Gtk.TreeListRow;
                var results = tree_list_row != null ? tree_list_row.item as ProcessScanner.Results : null;
                if (results != null) {
                    cell.update (results);
                }
            });
            columnview.append_column (name_column);

            memory_column = new Gtk.ColumnViewColumn (_("Memory"));
            memory_column.factory = new Gtk.SignalListItemFactory ();
            memory_column.factory.setup.connect ((factory, list_item) => {
                var cell = new MemoryCell ();
                list_item.child = cell;
            });
            memory_column.factory.bind.connect ((factory, list_item) => {
                var cell = list_item.child as MemoryCell;
                var tree_list_row = list_item.item as Gtk.TreeListRow;
                var results = tree_list_row != null ? tree_list_row.item as ProcessScanner.Results : null;
                if (results != null) {
                    cell.update (results);
                }
            });
            columnview.append_column (memory_column);

            var sorter = new Gtk.TreeListRowSorter (new ProcessMemorySorter ());
            sort_model = new Gtk.SortListModel (null, sorter);
            columnview_selection.model = sort_model;
        }

        private void setup_chart () {
            chart_model = new Gtk.StringList (null);
            chart_selection = new Gtk.NoSelection (chart_model);
            chart.model = chart_selection;
        }

        private void start_scan () {
            scanner.cancel ();
            scanner.scan ();
            nav_view.push (home_page);
        }

        private void on_scanner_completed () {
            if (scanner.root == null) {
                return;
            }

            tree_model = scanner.root.create_tree_model ();
            sort_model.model = tree_model;

            // Update chart with top processes
            chart_model.splice (0, chart_model.get_n_items (), null);
            
            // Get top processes by memory usage
            var processes = new Gee.ArrayList<ProcessScanner.Results> ();
            for (uint i = 0; i < scanner.root.children_list_store.get_n_items (); i++) {
                var results = scanner.root.children_list_store.get_item (i) as ProcessScanner.Results;
                if (results != null) {
                    processes.add (results);
                }
            }
            
            // Sort by memory usage
            processes.sort ((a, b) => {
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
                chart_model.append (results.display_name);
                count++;
            }

            nav_view.push (result_page);
        }

        [GtkCallback]
        private void on_scan_button_clicked () {
            start_scan ();
        }

        [GtkCallback]
        private void on_stop_button_clicked () {
            scanner.cancel ();
        }
    }

    private class ProcessMemorySorter : Gtk.Sorter {
        public override Gtk.Ordering compare (Object? a, Object? b) {
            var row_a = a as Gtk.TreeListRow;
            var row_b = b as Gtk.TreeListRow;

            if (row_a == null || row_b == null) {
                return Gtk.Ordering.EQUAL;
            }

            var results_a = row_a.item as ProcessScanner.Results;
            var results_b = row_b.item as ProcessScanner.Results;

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

        public override Gtk.SorterOrder get_order () {
            return Gtk.SorterOrder.PARTIAL;
        }
    }
}

