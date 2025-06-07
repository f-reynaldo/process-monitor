/* -*- tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - process memory usage analyzer
 *
 * Modified from original baobab-ringschart.vala
 * Original copyright:
 * Copyright (C) 2008  Igalia
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

    class RingschartItem : ChartItem {
        public double min_radius;
        public double max_radius;
        public double start_angle;
        public double angle;
        public bool continued;
    }

    public class Ringschart : Chart {

        const int ITEM_BORDER_WIDTH = 1;
        const double ITEM_MIN_ANGLE = 0.03;
        const double EDGE_ANGLE = 0.004;

        const int CHART_MARGIN = 20;
        const int HEADER_HEIGHT = 60;
        const int HEADER_FONT_SIZE = 14;
        const int ITEM_FONT_SIZE = 12;
        const int ITEM_DESCRIPTION_FONT_SIZE = 10;
        const int ITEM_DESCRIPTION_FONT_WEIGHT = 400;
        const double ITEM_DESCRIPTION_FONT_SCALE = 0.8;
        const int ITEM_DESCRIPTION_MAX_LINES = 2;
        const int ITEM_DESCRIPTION_MAX_CHARS = 20;
        const int ITEM_DESCRIPTION_MAX_CHARS_LAST_LINE = 20;

        protected override ChartItem create_chart_item() {
            return new RingschartItem();
        }

        protected override void draw_chart(Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
            if (items == null) {
                return;
            }

            int cx = width / 2;
            int cy = height / 2;
            int radius = int.min(width, height) / 2 - CHART_MARGIN;

            double ring_width = radius / 5.0;
            double max_depth = 0;

            foreach (var item in items) {
                if (item.depth > max_depth) {
                    max_depth = item.depth;
                }
            }

            if (max_depth > 0) {
                ring_width = radius / (max_depth + 1);
            }

            foreach (var item in items) {
                var ringschart_item = item as RingschartItem;

                ringschart_item.min_radius = item.depth * ring_width;
                ringschart_item.max_radius = (item.depth + 1) * ring_width;
                ringschart_item.start_angle = 2 * Math.PI * item.rel_start;
                ringschart_item.angle = 2 * Math.PI * item.rel_size;
                ringschart_item.continued = false;

                if (ringschart_item.angle < ITEM_MIN_ANGLE) {
                    ringschart_item.angle = ITEM_MIN_ANGLE;
                    ringschart_item.continued = true;
                }

                ringschart_item.visible = true;
            }

            foreach (var item in items) {
                var ringschart_item = item as RingschartItem;

                if (!ringschart_item.visible) {
                    continue;
                }

                double start_angle = ringschart_item.start_angle;
                double angle = ringschart_item.angle;
                double min_radius = ringschart_item.min_radius;
                double max_radius = ringschart_item.max_radius;

                if (ringschart_item.continued) {
                    angle -= 2 * EDGE_ANGLE;
                }

                // Draw the item
                cr.save();
                cr.move_to(cx, cy);
                cr.new_path();
                cr.arc(cx, cy, max_radius, start_angle, start_angle + angle);
                cr.arc_negative(cx, cy, min_radius, start_angle + angle, start_angle);
                cr.close_path();

                // Fill
                Gdk.RGBA fill_color;
                if (item == highlighted_item) {
                    fill_color = color_highlight;
                } else if (item == clicked_item) {
                    fill_color = color_clicked;
                } else {
                    fill_color = color_levels[item.depth % 10];
                }

                cr.set_source_rgb(fill_color.red, fill_color.green, fill_color.blue);
                cr.fill_preserve();

                // Stroke
                Gdk.RGBA stroke_color;
                if (item == highlighted_item) {
                    stroke_color = color_highlight_stroke;
                } else if (item == clicked_item) {
                    stroke_color = color_clicked_stroke;
                } else {
                    stroke_color = color_stroke;
                }

                cr.set_source_rgb(stroke_color.red, stroke_color.green, stroke_color.blue);
                cr.set_line_width(ITEM_BORDER_WIDTH);
                cr.stroke();
                cr.restore();

                // Draw the label
                if (item.depth > 0 && angle > 0.2) {
                    double mid_angle = start_angle + angle / 2;
                    double mid_radius = (min_radius + max_radius) / 2;

                    double x = cx + mid_radius * Math.cos(mid_angle);
                    double y = cy + mid_radius * Math.sin(mid_angle);

                    cr.save();
                    cr.translate(x, y);

                    if (mid_angle > Math.PI / 2 && mid_angle < 3 * Math.PI / 2) {
                        cr.rotate(mid_angle + Math.PI);
                    } else {
                        cr.rotate(mid_angle);
                    }

                    var layout = create_pango_layout(null);
                    layout.set_text(item.results.display_name, -1);

                    Pango.FontDescription font_desc = new Pango.FontDescription();
                    font_desc.set_size(ITEM_FONT_SIZE * Pango.SCALE);
                    layout.set_font_description(font_desc);

                    int text_width, text_height;
                    layout.get_pixel_size(out text_width, out text_height);

                    Gdk.RGBA text_color;
                    if (item == highlighted_item) {
                        text_color = color_highlight_text;
                    } else if (item == clicked_item) {
                        text_color = color_clicked_text;
                    } else {
                        text_color = color_text;
                    }

                    cr.set_source_rgb(text_color.red, text_color.green, text_color.blue);

                    if (mid_angle > Math.PI / 2 && mid_angle < 3 * Math.PI / 2) {
                        cr.move_to(-text_width - 5, -text_height / 2);
                    } else {
                        cr.move_to(5, -text_height / 2);
                    }

                    Pango.cairo_show_layout(cr, layout);
                    cr.restore();
                }
            }
            
            // Draw the model string in the center
            if (model_string != null && model_string.length > 0) {
                cr.save();
                
                var layout = create_pango_layout(null);
                layout.set_text(model_string, -1);
                layout.set_width(radius * Pango.SCALE);
                layout.set_alignment(Pango.Alignment.CENTER);
                
                Pango.FontDescription font_desc = new Pango.FontDescription();
                font_desc.set_size(HEADER_FONT_SIZE * Pango.SCALE);
                layout.set_font_description(font_desc);
                
                int text_width, text_height;
                layout.get_pixel_size(out text_width, out text_height);
                
                cr.set_source_rgb(color_text.red, color_text.green, color_text.blue);
                cr.move_to(cx - text_width / 2, cy - text_height / 2);
                
                Pango.cairo_show_layout(cr, layout);
                cr.restore();
            }
        }
    }
}

