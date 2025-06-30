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

[CCode (cprefix = "", cheader_filename = "config.h")]

namespace Baobab {

    [GtkTemplate (ui = "/org/gnome/baobab/ui/baobab-process-window.ui")]
    public class BaobabProcessWindow : Adw.ApplicationWindow {
        [GtkChild] private unowned Gtk.EventControllerFocus focus_controller;
        [GtkChild] private unowned Gtk.Widget home_page;
        [GtkChild] private unowned Gtk.Widget result_page;
        [GtkChild] private unowned Gtk.ColumnView columnview;
        [GtkChild] private unowned Gtk.SingleSelection columnview_selection;
        [GtkChild] private unowned Baobab.Chart chart;

        public BaobabProcessWindow () {
            Object (title: "Process Monitor");
            set_default_size (800, 600);

            // Set up the column view
            var model = new Gtk.ListStore (1, typeof (string)); // Process name
            columnview.set_model (new Gtk.SingleSelection (new Gtk.TreeListModel ((GLib.ListModel) model, false, false, null)));

            var factory = new Gtk.SignalListItemFactory ();
            factory.setup.connect ((list_item) => {
                var cell = new ProcessCell ();
                (list_item as Gtk.ListItem).set_child(cell);
            });
            factory.bind.connect ((list_item) => {
                var cell = (list_item as Gtk.ListItem).get_child() as ProcessCell;
                var tree_list_row = (list_item as Gtk.ListItem).get_child() as Gtk.TreeListRow;
                // Bind data to cell
            });
            // columnview.set_factory (factory); // Removed: Gtk.ColumnView does not have set_factory

            // Set up the memory column view
            var memory_model = new Gtk.ListStore (1, typeof (string)); // Memory usage
            // columnview.set_model (new Gtk.SingleSelection (Gtk.TreeListModel.new_with_model (memory_model, false, false))); // Commented out for now

            var memory_factory = new Gtk.SignalListItemFactory ();
            memory_factory.setup.connect ((list_item) => {
                var cell = new MemoryCell ();
                (list_item as Gtk.ListItem).set_child(cell);
            });
            memory_factory.bind.connect ((list_item) => {
                var cell = (list_item as Gtk.ListItem).get_child() as MemoryCell;
                var tree_list_row = (list_item as Gtk.ListItem).get_child() as Gtk.TreeListRow;
                // Bind data to cell
            });
            // columnview.set_factory (memory_factory); // Removed: Gtk.ColumnView does not have set_factory

            // Connect signals
            // focus_controller.focus_changed.connect ((widget) => { // Removed: Gtk.EventControllerFocus does not have focus_changed
            //     // Handle focus change
            // });

            // Example of switching pages
            // result_page.set_visible (true);
            // home_page.set_visible (false);
        }
    }
}


