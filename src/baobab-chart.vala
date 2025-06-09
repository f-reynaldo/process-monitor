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

        public weak ChartItem? parent_item;
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
        private const double ITEM_DESCRIPTION_FONT_SCALE = 0.8;
        private const int ITEM_DESCRIPTION_MAX_LINES = 2;
        private const int ITEM_DESCRIPTION_MAX_CHARS = 20;
        private const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE = 20;

        protected ProcessScanner.Results? root_;
        protected string model_string;
        protected Gtk.StringList model_;

        protected List<ChartItem> items;
        protected ChartItem? highlighted_item;
        protected ChartItem? clicked_item;
        protected ChartItem? context_item;

        private Gtk.GestureClick click_gesture;
        private Gtk.GestureClick right_click_gesture;
        private Gtk.EventControllerMotion motion_controller;
        private Gtk.EventControllerKey key_controller;
        private Gtk.PopoverMenu context_menu;

        private Gtk.CssProvider css_provider;

        private Pango.Layout layout;

        protected Gdk.RGBA color_fill;
        protected Gdk.RGBA color_stroke;
        protected Gdk.RGBA color_text;
        protected Gdk.RGBA color_description;
        protected Gdk.RGBA color_highlight;
        protected Gdk.RGBA color_highlight_stroke;
        protected Gdk.RGBA color_highlight_text;
        protected Gdk.RGBA color_highlight_description;
        protected Gdk.RGBA color_clicked;
        protected Gdk.RGBA color_clicked_stroke;
        protected Gdk.RGBA color_clicked_text;
        protected Gdk.RGBA color_clicked_description;

        protected Gdk.RGBA[] color_levels;

        protected Gdk.RGBA color_max_depth;
        protected Gdk.RGBA color_max_depth_stroke;
        protected Gdk.RGBA color_max_depth_text;
        protected Gdk.RGBA color_max_depth_description;

        protected Gdk.RGBA color_max_depth_highlight;
        protected Gdk.RGBA color_max_depth_highlight_stroke;
        protected Gdk.RGBA color_max_depth_highlight_text;
        protected Gdk.RGBA color_max_depth_highlight_description;

        protected Gdk.RGBA color_max_depth_clicked;
        protected Gdk.RGBA color_max_depth_clicked_stroke;
        protected Gdk.RGBA color_max_depth_clicked_text;
        protected Gdk.RGBA color_max_depth_clicked_description;

        protected Gdk.RGBA color_not_allocated;
        protected Gdk.RGBA color_not_allocated_stroke;
        protected Gdk.RGBA color_not_allocated_text;
        protected Gdk.RGBA color_not_allocated_description;

        protected Gdk.RGBA color_not_allocated_highlight;
        protected Gdk.RGBA color_not_allocated_highlight_stroke;
        protected Gdk.RGBA color_not_allocated_highlight_text;
        protected Gdk.RGBA color_not_allocated_highlight_description;

        protected Gdk.RGBA color_not_allocated_clicked;
        protected Gdk.RGBA color_not_allocated_clicked_stroke;
        protected Gdk.RGBA color_not_allocated_clicked_text;
        protected Gdk.RGBA color_not_allocated_clicked_description;

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
            style_context.notify["changed"].connect(on_style_changed);
            
            // Initialize colors
            on_style_changed();
        }

        private void on_style_changed() {
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
        }

        private Gdk.RGBA get_color(string name) {
            var style_context = get_style_context();
            Gdk.RGBA color;
            if (style_context.lookup_color(name, out color)) {
                return color;
            }
            return Gdk.RGBA();
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
                var children = new List<ProcessScanner.Results>();
                Gtk.TreeIter iter;
                if (item.results.children_list_store.get_iter_first(out iter)) {
                    do {
                        Value val;
                        item.results.children_list_store.get_value(iter, 0, out val);
                        ProcessScanner.Results? child = val.get_object() as ProcessScanner.Results;
                        if (child != null) {
                            children.append(child);
                        }
                    } while (item.results.children_list_store.iter_next(ref iter));
                }
                
                // Sort by memory usage
                CompareFunc<ProcessScanner.Results> reverse_size_cmp = (a, b) => {
                    if (a.memory_usage > b.memory_usage) {
                        return -1;
                    } else if (a.memory_usage < b.memory_usage) {
                        return 1;
                    } else {
                        return 0;
                    }
                };
                children.sort(reverse_size_cmp);

                double rel_start = 0.0;
                foreach (var child in children) {
                    double rel_size = (double) child.memory_usage / item.results.memory_usage;
                    var child_item = add_item(item.depth + 1, rel_start, rel_size, child);
                    child_item.parent_item = item;
                    queue.push_head(child_item);
                    rel_start += rel_size;
                }
            }
        }

        private void on_click_pressed(Gtk.GestureClick gesture, int n_press, double x, double y) {
            var item = get_item_at_position((int) x, (int) y);
            if (item != null) {
                clicked_item = item;
                queue_draw();
            }
        }

        private void on_click_released(Gtk.GestureClick gesture, int n_press, double x, double y) {
            clicked_item = null;
            queue_draw();
        }

        private void on_right_click_pressed(Gtk.GestureClick gesture, int n_press, double x, double y) {
            var item = get_item_at_position((int) x, (int) y);
            if (item != null) {
                context_item = item;
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

        private bool on_key_pressed(Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType state) {
            return false;
        }

        protected ChartItem? get_item_at_position(int x, int y) {
            if (items == null) {
                return null;
            }

            foreach (var item in items) {
                if (item.visible && item.rect.contains_point(x, y)) {
                    return item;
                }
            }

            return null;
        }

        protected abstract void draw_chart(Gtk.DrawingArea area, Cairo.Context cr, int width, int height);

        protected void draw_item(Cairo.Context cr, ChartItem item) {
            if (!item.visible) {
                return;
            }

            Gdk.RGBA fill_color;
            Gdk.RGBA stroke_color;
            Gdk.RGBA text_color;
            Gdk.RGBA description_color;

            if (item == clicked_item) {
                if (item.depth >= 10) {
                    fill_color = color_max_depth_clicked;
                    stroke_color = color_max_depth_clicked_stroke;
                    text_color = color_max_depth_clicked_text;
                    description_color = color_max_depth_clicked_description;
                } else {
                    fill_color = color_clicked;
                    stroke_color = color_clicked_stroke;
                    text_color = color_clicked_text;
                    description_color = color_clicked_description;
                }
            } else if (item == highlighted_item) {
                if (item.depth >= 10) {
                    fill_color = color_max_depth_highlight;
                    stroke_color = color_max_depth_highlight_stroke;
                    text_color = color_max_depth_highlight_text;
                    description_color = color_max_depth_highlight_description;
                } else {
                    fill_color = color_highlight;
                    stroke_color = color_highlight_stroke;
                    text_color = color_highlight_text;
                    description_color = color_highlight_description;
                }
            } else {
                if (item.depth >= 10) {
                    fill_color = color_max_depth;
                    stroke_color = color_max_depth_stroke;
                    text_color = color_max_depth_text;
                    description_color = color_max_depth_description;
                } else {
                    fill_color = color_levels[item.depth];
                    stroke_color = color_stroke;
                    text_color = color_text;
                    description_color = color_description;
                }
            }

            cr.set_source_rgba(fill_color.red, fill_color.green, fill_color.blue, fill_color.alpha);
            cr.rectangle(item.rect.x, item.rect.y, item.rect.width, item.rect.height);
            cr.fill_preserve();

            cr.set_source_rgba(stroke_color.red, stroke_color.green, stroke_color.blue, stroke_color.alpha);
            cr.set_line_width(1);
            cr.stroke();

            if (item.rect.width >= 20 && item.rect.height >= 20) {
                layout.set_text(item.results.display_name, -1);
                layout.set_width(item.rect.width * Pango.SCALE);
                layout.set_ellipsize(Pango.EllipsizeMode.END);

                int layout_width, layout_height;
                layout.get_pixel_size(out layout_width, out layout_height);

                if (layout_height < item.rect.height) {
                    cr.set_source_rgba(text_color.red, text_color.green, text_color.blue, text_color.alpha);
                    cr.move_to(item.rect.x + (item.rect.width - layout_width) / 2, item.rect.y + (item.rect.height - layout_height) / 2);
                    Pango.cairo_show_layout(cr, layout);
                }
            }
        }
    }
}

