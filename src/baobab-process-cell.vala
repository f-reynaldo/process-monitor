/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
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

    public class ProcessCell : Gtk.Box {
        private Gtk.Image icon;
        private Gtk.Label name_label;
        private Gtk.Label pid_label;

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 6;
            margin_start = 6;
            margin_end = 6;
            margin_top = 3;
            margin_bottom = 3;

            icon = new Gtk.Image.from_icon_name ("application-x-executable");
            icon.pixel_size = 16;
            append (icon);

            name_label = new Gtk.Label (null);
            name_label.xalign = 0;
            name_label.hexpand = true;
            append (name_label);

            pid_label = new Gtk.Label (null);
            pid_label.xalign = 1;
            pid_label.css_classes = { "dim-label" };
            append (pid_label);
        }

        public void update (ProcessScanner.Results results) {
            name_label.label = results.display_name;
            pid_label.label = results.pid.to_string ();
        }
    }
}

