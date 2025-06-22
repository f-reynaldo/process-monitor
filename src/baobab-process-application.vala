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

[CCode (cprefix = "", cheader_filename = "config.h")]

namespace Baobab {

    public class ProcessApplication : Adw.Application {
        private BaobabProcessWindow window;

        public ProcessApplication () {
            Object (application_id: "org.gnome.baobab.ProcessMonitor");
            this.window = new BaobabProcessWindow ();
        }

        protected override void activate () {
            window.present ();
        }

        protected override void open (File[] files, string hint) {
            activate ();
        }

        protected override void startup () {
            base.startup ();

            var about_action = new SimpleAction ("about", null);
            about_action.activate.connect (() => {
                var about_dialog = new Adw.AboutWindow ();
                about_dialog.application_name = "Process Monitor";
                about_dialog.application_icon = "org.gnome.baobab.ProcessMonitor";
                about_dialog.developer_name = "F. Reynaldo";
                about_dialog.version = "1.0";
                about_dialog.copyright = "Copyright © 2024 F. Reynaldo";
                about_dialog.website = "https://github.com/f-reynaldo/process-monitor";
                about_dialog.issue_url = "https://github.com/f-reynaldo/process-monitor/issues";
                about_dialog.license_type = Gtk.License.GPL_2_0;
                about_dialog.present ();
            });
            add_action (about_action);

            var quit_action = new SimpleAction ("quit", null);
            quit_action.activate.connect (() => {
                quit ();
            });
            add_action (quit_action);

            set_accels_for_action ("app.quit", { "<Primary>q" });
        }
    }
}


