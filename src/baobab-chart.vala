/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-chart.vala
 * Original copyright:
 * Copyright (C) 2006, 2007, 2008  Igalia
 * Copyright (C) 2013  Stefano Facchini <stefano.facchini@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor,
 * Boston, MA  02110-1301  USA
 */

namespace Baobab {

    public abstract class ChartItem {
        public uint depth;
        public double rel_start;
        public double rel_size;
        public ProcessScanner.Results results;
        public bool visible;
        public bool has_visible_children;
        public Gdk.Rectangle rect;

        public unowned List<ChartItem> parent;
    }

    public abstract class Chart : Gtk.DrawingArea {
        private const int ITEM_PADDING = 2;
        private const int HEADER_PADDING = 10;
        private const int HEADER_SPACING = 5;
        private const int HEADER_FONT_SIZE = 14;
        private const int ITEM_FONT_SIZE = 12;
        private const int ITEM_FONT_PADDING = 4;
        private const int ITEM_DESCRIPTION_PADDING = 4;
        private const int ITEM_DESCRIPTION_SPACING = 4;
        private const int ITEM_DESCRIPTION_FONT_SIZE = 10;
        private const int ITEM_DESCRIPTION_FONT_WEIGHT = 400;
        private const int ITEM_DESCRIPTION_FONT_SCALE = 0.8;
        private const int ITEM_DESCRIPTION_MAX_LINES = 2;
        private const int ITEM_DESCRIPTION_MAX_CHARS = 20;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE = 20;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_LONG = 40;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_LONG = 60;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_LONG = 80;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_LONG = 100;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_LONG = 120;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_LONG = 140;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 160;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 180;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 200;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 220;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 240;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 260;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 280;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 300;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 320;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 340;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 360;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 380;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 400;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 420;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 440;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 460;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 480;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_VERY_LONG = 500;

        private ProcessScanner.Results? root_;
        private string model_string;
        private Gtk.StringList model_;
        private Gtk.NoSelection selection_;

        private List<ChartItem> items;
        private ChartItem? highlighted_item;
        private ChartItem? clicked_item;
        private ChartItem? context_item;

        private Gtk.GestureClick click_gesture;
        private Gtk.GestureClick right_click_gesture;
        private Gtk.EventControllerMotion motion_controller;
        private Gtk.EventControllerKey key_controller;
        private Gtk.PopoverMenu context_menu;

        private Gtk.CssProvider css_provider;

        private Pango.Layout layout;

        private Gdk.RGBA color_fill;
        private Gdk.RGBA color_stroke;
        private Gdk.RGBA color_text;
        private Gdk.RGBA color_description;
        private Gdk.RGBA color_highlight;
        private Gdk.RGBA color_highlight_stroke;
        private Gdk.RGBA color_highlight_text;
        private Gdk.RGBA color_highlight_description;
        private Gdk.RGBA color_clicked;
        private Gdk.RGBA color_clicked_stroke;
        private Gdk.RGBA color_clicked_text;
        private Gdk.RGBA color_clicked_description;

        private Gdk.RGBA[] color_levels;

        private Gdk.RGBA color_max_depth;
        private Gdk.RGBA color_max_depth_stroke;
        private Gdk.RGBA color_max_depth_text;
        private Gdk.RGBA color_max_depth_description;

        private Gdk.RGBA color_max_depth_highlight;
        private Gdk.RGBA color_max_depth_highlight_stroke;
        private Gdk.RGBA color_max_depth_highlight_text;
        private Gdk.RGBA color_max_depth_highlight_description;

        private Gdk.RGBA color_max_depth_clicked;
        private Gdk.RGBA color_max_depth_clicked_stroke;
        private Gdk.RGBA color_max_depth_clicked_text;
        private Gdk.RGBA color_max_depth_clicked_description;

        private Gdk.RGBA color_not_allocated;
        private Gdk.RGBA color_not_allocated_stroke;
        private Gdk.RGBA color_not_allocated_text;
        private Gdk.RGBA color_not_allocated_description;

        private Gdk.RGBA color_not_allocated_highlight;
        private Gdk.RGBA color_not_allocated_highlight_stroke;
        private Gdk.RGBA color_not_allocated_highlight_text;
        private Gdk.RGBA color_not_allocated_highlight_description;

        private Gdk.RGBA color_not_allocated_clicked;
        private Gdk.RGBA color_not_allocated_clicked_stroke;
        private Gdk.RGBA color_not_allocated_clicked_text;
        private Gdk.RGBA color_not_allocated_clicked_description;

        public Gtk.StringList model {
            get { return model_; }
            set {
                model_ = value;
                model_string = "";
                if (model_ != null) {
                    for (uint i = 0; i < model_.get_n_items(); i++) {
                        model_string += model_.get_string(i) + "\n";
                    }
                }
                queue_draw();
            }
        }

        public Gtk.NoSelection selection {
            get { return selection_; }
            set {
                selection_ = value;
                if (selection_ != null) {
                    model = selection_.model as Gtk.StringList;
                }
            }
        }

        public ProcessScanner.Results? tree_root {
            get { return root_; }
            set {
                root_ = value;
                get_items(root_);
                queue_draw();
            }
        }

        construct {
            set_draw_func(draw_chart);

            click_gesture = new Gtk.GestureClick();
            click_gesture.set_button(1);
            click_gesture.pressed.connect(on_click_pressed);
            click_gesture.released.connect(on_click_released);
            add_controller(click_gesture);

            right_click_gesture = new Gtk.GestureClick();
            right_click_gesture.set_button(3);
            right_click_gesture.pressed.connect(on_right_click_pressed);
            add_controller(right_click_gesture);

            motion_controller = new Gtk.EventControllerMotion();
            motion_controller.motion.connect(on_motion);
            motion_controller.leave.connect(on_leave);
            add_controller(motion_controller);

            key_controller = new Gtk.EventControllerKey();
            key_controller.key_pressed.connect(on_key_pressed);
            add_controller(key_controller);

            var builder = new Gtk.Builder.from_resource("/org/gnome/baobab/ui/baobab-chart-menu.ui");
            context_menu = new Gtk.PopoverMenu.from_model(builder.get_object("chart-menu") as MenuModel);
            context_menu.set_parent(this);

            css_provider = new Gtk.CssProvider();
            css_provider.load_from_resource("/org/gnome/baobab/ui/baobab-chart.css");
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            layout = create_pango_layout(null);

            color_levels = new Gdk.RGBA[10];
            for (int i = 0; i < 10; i++) {
                color_levels[i] = Gdk.RGBA();
            }

            var style_context = get_style_context();
            style_context.changed.connect(() => {
                color_fill = get_color("chart-fill");
                color_stroke = get_color("chart-stroke");
                color_text = get_color("chart-text");
                color_description = get_color("chart-description");
                color_highlight = get_color("chart-highlight");
                color_highlight_stroke = get_color("chart-highlight-stroke");
                color_highlight_text = get_color("chart-highlight-text");
                color_highlight_description = get_color("chart-highlight-description");
                color_clicked = get_color("chart-clicked");
                color_clicked_stroke = get_color("chart-clicked-stroke");
                color_clicked_text = get_color("chart-clicked-text");
                color_clicked_description = get_color("chart-clicked-description");

                color_levels[0] = get_color("chart-level-0");
                color_levels[1] = get_color("chart-level-1");
                color_levels[2] = get_color("chart-level-2");
                color_levels[3] = get_color("chart-level-3");
                color_levels[4] = get_color("chart-level-4");
                color_levels[5] = get_color("chart-level-5");
                color_levels[6] = get_color("chart-level-6");
                color_levels[7] = get_color("chart-level-7");
                color_levels[8] = get_color("chart-level-8");
                color_levels[9] = get_color("chart-level-9");

                color_max_depth = get_color("chart-max-depth");
                color_max_depth_stroke = get_color("chart-max-depth-stroke");
                color_max_depth_text = get_color("chart-max-depth-text");
                color_max_depth_description = get_color("chart-max-depth-description");

                color_max_depth_highlight = get_color("chart-max-depth-highlight");
                color_max_depth_highlight_stroke = get_color("chart-max-depth-highlight-stroke");
                color_max_depth_highlight_text = get_color("chart-max-depth-highlight-text");
                color_max_depth_highlight_description = get_color("chart-max-depth-highlight-description");

                color_max_depth_clicked = get_color("chart-max-depth-clicked");
                color_max_depth_clicked_stroke = get_color("chart-max-depth-clicked-stroke");
                color_max_depth_clicked_text = get_color("chart-max-depth-clicked-text");
                color_max_depth_clicked_description = get_color("chart-max-depth-clicked-description");

                color_not_allocated = get_color("chart-not-allocated");
                color_not_allocated_stroke = get_color("chart-not-allocated-stroke");
                color_not_allocated_text = get_color("chart-not-allocated-text");
                color_not_allocated_description = get_color("chart-not-allocated-description");

                color_not_allocated_highlight = get_color("chart-not-allocated-highlight");
                color_not_allocated_highlight_stroke = get_color("chart-not-allocated-highlight-stroke");
                color_not_allocated_highlight_text = get_color("chart-not-allocated-highlight-text");
                color_not_allocated_highlight_description = get_color("chart-not-allocated-highlight-description");

                color_not_allocated_clicked = get_color("chart-not-allocated-clicked");
                color_not_allocated_clicked_stroke = get_color("chart-not-allocated-clicked-stroke");
                color_not_allocated_clicked_text = get_color("chart-not-allocated-clicked-text");
                color_not_allocated_clicked_description = get_color("chart-not-allocated-clicked-description");

                queue_draw();
            });
        }

        private Gdk.RGBA get_color(string name) {
            var style_context = get_style_context();
            return style_context.lookup_color(name).color;
        }

        private unowned List<ChartItem> add_item(uint depth, double rel_start, double rel_size, ProcessScanner.Results results) {
            var item = create_chart_item();
            item.depth = depth;
            item.rel_start = rel_start;
            item.rel_size = rel_size;
            item.results = results;
            item.visible = false;
            item.has_visible_children = false;
            item.rect = Gdk.Rectangle();

            items.append(item);
            return items.last();
        }

        protected abstract ChartItem create_chart_item();

        private void get_items(ProcessScanner.Results? root_path) {
            items = new List<ChartItem>();
            highlighted_item = null;
            clicked_item = null;
            context_item = null;

            if (root_path == null) {
                return;
            }

            var root_item = add_item(0, 0.0, 1.0, root_path);

            var queue = new Queue<unowned List<ChartItem>>();
            queue.push_head(root_item);

            while (!queue.is_empty()) {
                var item_link = queue.pop_head();
                var item = item_link.data;

                if (item.results.is_empty) {
                    continue;
                }

                // Sort children by size
                CompareDataFunc<ProcessScanner.Results> reverse_size_cmp = (a, b) => {
                    if (a.memory_usage > b.memory_usage) {
                        return -1;
                    } else if (a.memory_usage < b.memory_usage) {
                        return 1;
                    } else {
                        return 0;
                    }
                };

                var sorted = new GLib.ListStore(typeof(ProcessScanner.Results));
                for (uint i = 0; i < item.results.children_list_store.get_n_items(); i++) {
                    sorted.append(item.results.children_list_store.get_item(i));
                }
                sorted.sort(reverse_size_cmp);

                double rel_start = 0.0;
                for (uint i = 0; i < sorted.get_n_items(); i++) {
                    var child_iter = sorted.get_object(i) as ProcessScanner.Results;
                    if (child_iter == null) {
                        continue;
                    }

                    double rel_size = 0.0;
                    if (item.results.memory_usage > 0) {
                        rel_size = (double) child_iter.memory_usage / (double) item.results.memory_usage;
                    }

                    if (rel_size <= 0.0) {
                        continue;
                    }

                    var child_item = add_item(item.depth + 1, rel_start, rel_size, child_iter);
                    child_item.parent = item_link;
                    rel_start += rel_size;

                    queue.push_head(child_item);
                }
            }
        }

        public signal void item_activated(ProcessScanner.Results item);

        private void draw_chart(Gtk.DrawingArea drawing_area, Cairo.Context cr, int width, int height) {
            if (model_string != null && model_string != "") {
                layout.set_text(model_string, -1);
                layout.set_width(width * Pango.SCALE);
                layout.set_alignment(Pango.Alignment.CENTER);
                layout.set_wrap(Pango.WrapMode.WORD_CHAR);

                int layout_width, layout_height;
                layout.get_pixel_size(out layout_width, out layout_height);

                cr.set_source_rgb(color_text.red, color_text.green, color_text.blue);
                cr.move_to((width - layout_width) / 2, (height - layout_height) / 2);
                Pango.cairo_show_layout(cr, layout);
                return;
            }

            if (items == null) {
                return;
            }

            draw_chart_items(cr, width, height);
        }

        protected abstract void draw_chart_items(Cairo.Context cr, int width, int height);

        private bool on_key_pressed(Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
            if (keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) {
                if (highlighted_item != null) {
                    item_activated(highlighted_item.results);
                    return true;
                }
            }

            return false;
        }

        private void on_click_pressed(Gtk.GestureClick gesture, int n_press, double x, double y) {
            clicked_item = get_item_at_position((int) x, (int) y);
            queue_draw();
        }

        private void on_click_released(Gtk.GestureClick gesture, int n_press, double x, double y) {
            var item = get_item_at_position((int) x, (int) y);
            if (item != null && item == clicked_item) {
                item_activated(item.results);
            }

            clicked_item = null;
            queue_draw();
        }

        private void on_right_click_pressed(Gtk.GestureClick gesture, int n_press, double x, double y) {
            context_item = get_item_at_position((int) x, (int) y);
            if (context_item != null) {
                context_menu.popup();
            }
        }

        private void on_motion(Gtk.EventControllerMotion controller, double x, double y) {
            var item = get_item_at_position((int) x, (int) y);
            if (item != highlighted_item) {
                highlighted_item = item;
                queue_draw();
            }
        }

        private void on_leave(Gtk.EventControllerMotion controller) {
            if (highlighted_item != null) {
                highlighted_item = null;
                queue_draw();
            }
        }

        protected abstract ChartItem? get_item_at_position(int x, int y);
    }
}

