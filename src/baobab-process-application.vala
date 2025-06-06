/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-application.vala
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
    public class ProcessApplication : Adw.Application {
        private ProcessWindow window;

        const OptionEntry[] option_entries = {
            { "version", 'v', 0, OptionArg.NONE, null, N_("Print version information and exit"), null },
            { null }
        };

        public ProcessApplication () {
            Object (application_id: "org.gnome.baobab.ProcessMonitor",
                   flags: ApplicationFlags.FLAGS_NONE);

            add_main_option_entries (option_entries);
        }

        protected override void activate () {
            if (window == null) {
                window = new ProcessWindow ();
                window.application = this;
            }

            window.present ();
        }

        protected override int handle_local_options (VariantDict options) {
            if (options.contains ("version")) {
                print ("%s %s\n", "Process Monitor", Config.VERSION);
                return 0;
            }

            return -1;
        }
    }
}

