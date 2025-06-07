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

    public class MemoryCell : Gtk.Box {
        private Gtk.Label size_label;
        private Gtk.Label percent_label;

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 6;
            margin_start = 6;
            margin_end = 6;
            margin_top = 3;
            margin_bottom = 3;

            size_label = new Gtk.Label (null);
            size_label.xalign = 0;
            size_label.hexpand = true;
            append (size_label);

            percent_label = new Gtk.Label (null);
            percent_label.xalign = 1;
            append (percent_label);
        }

        public void update (ProcessScanner.Results results) {
            size_label.label = format_size (results.memory_usage);
            percent_label.label = "%.1f%%".printf (results.percent);
        }

        private string format_size (uint64 size) {
            string[] units = { "B", "KB", "MB", "GB", "TB" };
            double dsize = (double) size;
            int unit = 0;

            while (dsize >= 1024 && unit < units.length - 1) {
                dsize /= 1024;
                unit++;
            }

            if (unit == 0) {
                return "%.0f %s".printf (dsize, units[unit]);
            } else {
                return "%.1f %s".printf (dsize, units[unit]);
            }
        }
    }
}

