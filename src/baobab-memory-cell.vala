/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-size-cell.vala
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
    public class MemoryCell : Gtk.Box {
        private Gtk.Label memory_label;
        private Gtk.Label percent_label;

        public MemoryCell () {
            Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 6);

            memory_label = new Gtk.Label (null);
            memory_label.xalign = 1.0f;
            memory_label.width_chars = 10;
            memory_label.get_style_context ().add_class ("dim-label");
            this.append (memory_label);

            percent_label = new Gtk.Label (null);
            percent_label.xalign = 1.0f;
            percent_label.width_chars = 6;
            this.append (percent_label);
        }

        public void update (ProcessScanner.Results results) {
            memory_label.label = format_size (results.memory_usage);
            percent_label.label = "%.1f%%".printf (results.percent);
        }
    }
}

