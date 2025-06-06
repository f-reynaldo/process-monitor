/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-file-cell.vala
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
    public class ProcessCell : Gtk.Box {
        private Gtk.Label name_label;
        private Gtk.Label pid_label;

        public ProcessCell () {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 6);

            name_label = new Gtk.Label (null);
            name_label.xalign = 0.0f;
            name_label.ellipsize = Pango.EllipsizeMode.END;
            name_label.hexpand = true;
            this.append (name_label);

            pid_label = new Gtk.Label (null);
            pid_label.xalign = 1.0f;
            pid_label.get_style_context ().add_class ("dim-label");
            this.append (pid_label);
        }

        public void update (ProcessScanner.Results results) {
            name_label.label = results.display_name;
            if (results.pid > 0) {
                pid_label.label = "[%d]".printf (results.pid);
            } else {
                pid_label.label = "";
            }
        }
    }
}

