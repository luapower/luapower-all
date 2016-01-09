---
tagline: cairo graphics engine
---

## `local cairo = require'cairo'`

A lightweight ffi binding of the [cairo graphics] library.


## Features

  * cairo types have associated methods, so you can use `context:paint()`
  instead of `cairo.cairo_paint(context)`
  * pointers to objects for which cairo holds no references are bound to
  Lua's garbage collector to prevent leaks
  * ref-counted objects have a free() method that checks ref. count and a
  destroy() method that doesn't.
  * functions that work with `char*` are made to accept/return Lua strings.
  * output buffers are optional - if not passed on as arguments, temporary
  buffers are allocated instead; the values in the buffers are then returned
  as multiple return values, such as in
  `context:clip_extents([dx1][,dy1][,dx2[,dy2]) -> x1, y1, x2, y2`,
  where dx1 etc. are `double[1]` buffers.
  * the included binary is built with support for in-memory surfaces,
  recording surfaces, ps surfaces, pdf surfaces, svg surfaces, win32 surfaces,
  win32 fonts and freetype fonts.

See the [cairo manual] for the function list, remembering that method call
style is available for them.

Additional wrappers are provided for completeness:

<div class="small">
-------------------------------------------- ------------------------------------------------
`cr:quad_curve_to(x1, y1, x2, y2)`           add a quad bezier to the current path
`cr:rel_quad_curve_to(x1, y1, x2, y2)`       add a relative quad bezier to the current path
`cr:circle(cx, cy, r)`                       add a circle to the current path
`cr:ellipse(cx, cy, rx, ry)`                 add an ellipse to the current path
`cr:skew(ax, ay)`                            skew current matrix
`cr:rotate_around(cx, cy, angle)`            rotate current matrix around point
`cr:safe_transform(mt)`                      transform current matrix if possible
`mt:transform(with_mt) -> mt`                transform matrix with other matrix
`mt:invertible() -> true|false`              is matrix invertible?
`mt:safe_transform(with_mt)`                 transform matrix if possible
`mt:skew(ax, ay)`                            skew matrix
`mt:rotate_around(cx, cy, angle)`            rotate matrix around point
`surface:apply_alpha(alpha)`                 make surface transparent
-------------------------------------------- ------------------------------------------------

Also, `cairo.cairo_image_surface_create_from_bitmap(bmp) -> surface`
creates a cairo image surface from a [bitmap] object if it's in one
of the supported formats: 'bgra8', 'bgrx8', 'g8', 'g1', 'rgb565'.

[cairo graphics]:   http://cairographics.org/
[cairo manual]:     http://cairographics.org/manual/


## API

------------------------------------------- -----------------------------------------------------
__drawing contexts__
`cr:save()`                                 [save state (push to stack)][cairo_save]
`cr:restore()`                              [restore state (pop from stack)][cairo_restore]
`cr:push_group()`                           [ref][cairo_push_group]
`cr:push_group_with_content()`              [ref][cairo_push_group_with_content]
`cr:pop_group()`                            [ref][cairo_pop_group]
`cr:pop_group_to_source()`                  [ref][cairo_pop_group_to_source]
`cr:set_operator()`                         [ref][cairo_set_operator]
`cr:set_source()`                           [ref][cairo_set_source]
`cr:set_source_rgb()`                       [ref][cairo_set_source_rgb]
`cr:set_source_rgba()`                      [ref][cairo_set_source_rgba]
`cr:set_source_surface()`                   [ref][cairo_set_source_surface]
`cr:set_tolerance()`                        [ref][cairo_set_tolerance]
`cr:set_antialias()`                        [ref][cairo_set_antialias]
`cr:set_fill_rule()`                        [ref][cairo_set_fill_rule]
`cr:set_line_width()`                       [ref][cairo_set_line_width]
`cr:set_line_cap()`                         [ref][cairo_set_line_cap]
`cr:set_line_join()`                        [ref][cairo_set_line_join]
`cr:set_dash()`                             [ref][cairo_set_dash]
`cr:set_miter_limit()`                      [ref][cairo_set_miter_limit]
`cr:translate()`                            [ref][cairo_translate]
`cr:scale()`                                [ref][cairo_scale]
`cr:rotate()`                               [ref][cairo_rotate]
`cr:rotate_around()`                        [ref][cairo_rotate_around]
`cr:scale_around()`                         [ref][cairo_scale_around]
`cr:transform()`                            [ref][cairo_transform]
`cr:safe_transform()`                       [ref][cairo_safe_transform]
`cr:set_matrix()`                           [ref][cairo_set_matrix]
`cr:identity_matrix()`                      [ref][cairo_identity_matrix]
`cr:skew()`                                 [ref][cairo_skew]
`cr:user_to_device()`                       [ref][cairo_user_to_device]
`cr:user_to_device_distance()`              [ref][cairo_user_to_device_distance]
`cr:device_to_user()`                       [ref][cairo_device_to_user]
`cr:device_to_user_distance()`              [ref][cairo_device_to_user_distance]
`cr:new_path()`                             [ref][cairo_new_path]
`cr:move_to()`                              [ref][cairo_move_to]
`cr:new_sub_path()`                         [ref][cairo_new_sub_path]
`cr:line_to()`                              [ref][cairo_line_to]
`cr:curve_to()`                             [ref][cairo_curve_to]
`cr:quad_curve_to()`                        [ref][cairo_quad_curve_to]
`cr:arc()`                                  [ref][cairo_arc]
`cr:arc_negative()`                         [ref][cairo_arc_negative]
`cr:circle()`                               [ref][cairo_circle]
`cr:ellipse()`                              [ref][cairo_ellipse]
`cr:rel_move_to()`                          [ref][cairo_rel_move_to]
`cr:rel_line_to()`                          [ref][cairo_rel_line_to]
`cr:rel_curve_to()`                         [ref][cairo_rel_curve_to]
`cr:rel_quad_curve_to()`                    [ref][cairo_rel_quad_curve_to]
`cr:rectangle()`                            [ref][cairo_rectangle]
`cr:close_path()`                           [ref][cairo_close_path]
`cr:path_extents()`                         [ref][cairo_path_extents]
`cr:paint()`                                [ref][cairo_paint]
`cr:paint_with_alpha()`                     [ref][cairo_paint_with_alpha]
`cr:mask()`                                 [ref][cairo_mask]
`cr:mask_surface()`                         [ref][cairo_mask_surface]
`cr:stroke()`                               [ref][cairo_stroke]
`cr:stroke_preserve()`                      [ref][cairo_stroke_preserve]
`cr:fill()`                                 [ref][cairo_fill]
`cr:fill_preserve()`                        [ref][cairo_fill_preserve]
`cr:copy_page()`                            [ref][cairo_copy_page]
`cr:show_page()`                            [ref][cairo_show_page]
`cr:in_stroke()`                            [ref][cairo_in_stroke]
`cr:in_fill()`                              [ref][cairo_in_fill]
`cr:in_clip()`                              [ref][cairo_in_clip]
`cr:stroke_extents()`                       [ref][cairo_stroke_extents]
`cr:fill_extents()`                         [ref][cairo_fill_extents]
`cr:reset_clip()`                           [ref][cairo_reset_clip]
`cr:clip()`                                 [ref][cairo_clip]
`cr:clip_preserve()`                        [ref][cairo_clip_preserve]
`cr:clip_extents()`                         [ref][cairo_clip_extents]
`cr:copy_clip_rectangle_list()`             [ref][cairo_copy_clip_rectangle_list]
`cr:select_font_face()`                     [ref][cairo_select_font_face]
`cr:set_font_size()`                        [ref][cairo_set_font_size]
`cr:set_font_matrix()`                      [ref][cairo_set_font_matrix]
`cr:get_font_matrix()`                      [ref][cairo_get_font_matrix]
`cr:set_font_options()`                     [ref][cairo_set_font_options]
`cr:get_font_options()`                     [ref][cairo_get_font_options]
`cr:set_font_face()`                        [ref][cairo_set_font_face]
`cr:get_font_face()`                        [ref][cairo_get_font_face]
`cr:set_scaled_font()`                      [ref][cairo_set_scaled_font]
`cr:get_scaled_font()`                      [ref][cairo_get_scaled_font]
`cr:show_text()`                            [ref][cairo_show_text]
`cr:show_glyphs()`                          [ref][cairo_show_glyphs]
`cr:show_text_glyphs()`                     [ref][cairo_show_text_glyphs]
`cr:text_path()`                            [ref][cairo_text_path]
`cr:glyph_path()`                           [ref][cairo_glyph_path]
`cr:text_extents()`                         [ref][cairo_text_extents]
`cr:glyph_extents()`                        [ref][cairo_glyph_extents]
`cr:font_extents()`                         [ref][cairo_font_extents]
`cr:get_operator()`                         [ref][cairo_get_operator]
`cr:get_source()`                           [ref][cairo_get_source]
`cr:get_tolerance()`                        [ref][cairo_get_tolerance]
`cr:get_antialias()`                        [ref][cairo_get_antialias]
`cr:has_current_point()`                    [ref][cairo_has_current_point]
`cr:get_current_point()`                    [ref][cairo_get_current_point]
`cr:get_fill_rule()`                        [ref][cairo_get_fill_rule]
`cr:get_line_width()`                       [ref][cairo_get_line_width]
`cr:get_line_cap()`                         [ref][cairo_get_line_cap]
`cr:get_line_join()`                        [ref][cairo_get_line_join]
`cr:get_miter_limit()`                      [ref][cairo_get_miter_limit]
`cr:get_dash_count()`                       [ref][cairo_get_dash_count]
`cr:get_dash()`                             [ref][cairo_get_dash]
`cr:get_matrix()`                           [ref][cairo_get_matrix]
`cr:get_target()`                           [ref][cairo_get_target]
`cr:get_group_target()`                     [ref][cairo_get_group_target]
`cr:copy_path()`                            [ref][cairo_copy_path]
`cr:copy_path_flat()`                       [ref][cairo_copy_path_flat]
`cr:append_path()`                          [ref][cairo_append_path]
`cr:status()`                               [ref][cairo_status]
`cr:status_string()`                        [ref][cairo_status_string]
`cr:get_user_data(key)`                     [ref][cairo_get_user_data]
`cr:set_user_data(key, val[, destroy])`     [ref][cairo_set_user_data]
`cr:reference()`                            [ref][cairo_reference]
`cr:get_reference_count()`                  [ref][cairo_get_reference_count]
`cr:destroy()`                              [ref][cairo_destroy]
`cr:free()`                                 free (error if ref count > 0)
__surfaces__
`sr:create_context()`                       [ref][cairo_create_context]
`sr:create_similar()`                       [ref][cairo_create_similar]
`sr:create_for_rectangle()`                 [ref][cairo_create_for_rectangle]
`sr:finish()`                               [ref][cairo_finish]
`sr:get_device()`                           [ref][cairo_get_device]
`sr:status()`                               [ref][cairo_status]
`sr:status_string()`                        [ref][cairo_status_string]
`sr:get_type()`                             [ref][cairo_get_type]
`sr:get_content()`                          [ref][cairo_get_content]
`sr:write_to_png()`                         [ref][cairo_write_to_png]
`sr:write_to_png_stream()`                  [ref][cairo_write_to_png_stream]
`sr:get_user_data()`                        [ref][cairo_get_user_data]
`sr:set_user_data()`                        [ref][cairo_set_user_data]
`sr:get_mime_data()`                        [ref][cairo_get_mime_data]
`sr:set_mime_data()`                        [ref][cairo_set_mime_data]
`sr:get_font_options()`                     [ref][cairo_get_font_options]
`sr:flush()`                                [ref][cairo_flush]
`sr:mark_dirty()`                           [ref][cairo_mark_dirty]
`sr:mark_dirty_rectangle()`                 [ref][cairo_mark_dirty_rectangle]
`sr:set_device_offset()`                    [ref][cairo_set_device_offset]
`sr:get_device_offset()`                    [ref][cairo_get_device_offset]
`sr:set_fallback_resolution()`              [ref][cairo_set_fallback_resolution]
`sr:get_fallback_resolution()`              [ref][cairo_get_fallback_resolution]
`sr:copy_page()`                            [ref][cairo_copy_page]
`sr:show_page()`                            [ref][cairo_show_page]
`sr:has_show_text_glyphs()`                 [ref][cairo_has_show_text_glyphs]
`sr:create_pattern()`                       [ref][cairo_create_pattern]
`sr:apply_alpha()`                          [ref][cairo_apply_alpha]
`sr:reference()`                            [ref][cairo_reference]
`sr:get_reference_count()`                  [ref][cairo_get_reference_count]
`sr:destroy()`                              [ref][cairo_destroy]
`sr:free()`                                 free (error if ref count > 0)
`sr:get_image_data()`                       [ref][cairo_get_image_data]
`sr:get_image_format()`                     [ref][cairo_get_image_format]
`sr:get_image_width()`                      [ref][cairo_get_image_width]
`sr:get_image_height()`                     [ref][cairo_get_image_height]
`sr:get_image_stride()`                     [ref][cairo_get_image_stride]
`sr:get_image_bpp()`                        [ref][cairo_get_image_bpp]
`sr:get_image_pixel_function()`             [ref][cairo_get_image_pixel_function]
`sr:set_image_pixel_function()`             [ref][cairo_set_image_pixel_function]
__devices__
`dev:get_type()`                            [ref][cairo_get_type]
`dev:status()`                              [ref][cairo_status]
`dev:status_string()`                       [ref][cairo_status_string]
`dev:acquire()`                             [ref][cairo_acquire]
`dev:release()`                             [ref][cairo_release]
`dev:flush()`                               [ref][cairo_flush]
`dev:finish()`                              [ref][cairo_finish]
`dev:get_user_data()`                       [ref][cairo_get_user_data]
`dev:set_user_data()`                       [ref][cairo_set_user_data]
`dev:reference()`                           [ref][cairo_reference]
`dev:get_reference_count()`                 [ref][cairo_get_reference_count]
`dev:destroy()`                             [ref][cairo_destroy]
`dev:free()`                                free (error if ref count > 0)
__patterns__
`patt:status()`                             [ref][cairo_status]
`patt:status_string()`                      [ref][cairo_status_string]
`patt:get_user_data()`                      [ref][cairo_get_user_data]
`patt:set_user_data()`                      [ref][cairo_set_user_data]
`patt:get_type()`                           [ref][cairo_get_type]
`patt:add_color_stop_rgb()`                 [ref][cairo_add_color_stop_rgb]
`patt:add_color_stop_rgba()`                [ref][cairo_add_color_stop_rgba]
`patt:set_matrix()`                         [ref][cairo_set_matrix]
`patt:get_matrix()`                         [ref][cairo_get_matrix]
`patt:set_extend()`                         [ref][cairo_set_extend]
`patt:get_extend()`                         [ref][cairo_get_extend]
`patt:set_filter()`                         [ref][cairo_set_filter]
`patt:get_filter()`                         [ref][cairo_get_filter]
`patt:get_rgba()`                           [ref][cairo_get_rgba]
`patt:get_surface()`                        [ref][cairo_get_surface]
`patt:get_color_stop_rgba()`                [ref][cairo_get_color_stop_rgba]
`patt:get_color_stop_count()`               [ref][cairo_get_color_stop_count]
`patt:get_linear_points()`                  [ref][cairo_get_linear_points]
`patt:get_radial_circles()`                 [ref][cairo_get_radial_circles]
`patt:reference()`                          [ref][cairo_reference]
`patt:get_reference_count()`                [ref][cairo_get_reference_count]
`patt:destroy()`                            [ref][cairo_destroy]
`patt:free()`                               free (error if ref count > 0)
__scaled fonts__
`sfont:status()`                            [ref][cairo_status]
`sfont:status_string()`                     [ref][cairo_status_string]
`sfont:get_type()`                          [ref][cairo_get_type]
`sfont:get_user_data()`                     [ref][cairo_get_user_data]
`sfont:set_user_data()`                     [ref][cairo_set_user_data]
`sfont:extents()`                           [ref][cairo_extents]
`sfont:text_extents()`                      [ref][cairo_text_extents]
`sfont:glyph_extents()`                     [ref][cairo_glyph_extents]
`sfont:text_to_glyphs()`                    [ref][cairo_text_to_glyphs]
`sfont:get_font_face()`                     [ref][cairo_get_font_face]
`sfont:get_font_matrix()`                   [ref][cairo_get_font_matrix]
`sfont:get_ctm()`                           [ref][cairo_get_ctm]
`sfont:get_scale_matrix()`                  [ref][cairo_get_scale_matrix]
`sfont:get_font_options()`                  [ref][cairo_get_font_options]
`sfont:reference()`                         [ref][cairo_reference]
`sfont:get_reference_count()`               [ref][cairo_get_reference_count]
`sfont:destroy()`                           [ref][cairo_destroy]
`sfont:free()`                              free (error if ref count > 0)
__font faces__
`font:status()`                             [ref][cairo_status]
`font:status_string()`                      [ref][cairo_status_string]
`font:get_type()`                           [ref][cairo_get_type]
`font:get_user_data()`                      [ref][cairo_get_user_data]
`font:set_user_data()`                      [ref][cairo_set_user_data]
`font:create_scaled_font()`                 [ref][cairo_create_scaled_font]
`font:toy_get_family()`                     [ref][cairo_toy_get_family]
`font:toy_get_slant()`                      [ref][cairo_toy_get_slant]
`font:toy_get_weight()`                     [ref][cairo_toy_get_weight]
`font:user_set_init_func()`                 [ref][cairo_user_set_init_func]
`font:user_set_render_glyph_func()`         [ref][cairo_user_set_render_glyph_func]
`font:user_set_text_to_glyphs_func()`       [ref][cairo_user_set_text_to_glyphs_func]
`font:user_set_unicode_to_glyph_func()`     [ref][cairo_user_set_unicode_to_glyph_func]
`font:user_get_init_func()`                 [ref][cairo_user_get_init_func]
`font:user_get_render_glyph_func()`         [ref][cairo_user_get_render_glyph_func]
`font:user_get_text_to_glyphs_func()`       [ref][cairo_user_get_text_to_glyphs_func]
`font:user_get_unicode_to_glyph_func()`     [ref][cairo_user_get_unicode_to_glyph_func]
`font:reference()`                          [ref][cairo_reference]
`font:get_reference_count()`                [ref][cairo_get_reference_count]
`font:destroy()`                            [ref][cairo_destroy]
`font:free()`                               free (error if ref count > 0)
__font options__
`fopt:copy()`                               [ref][cairo_copy]
`fopt:free()`                               [ref][cairo_free]
`fopt:status()`                             [ref][cairo_status]
`fopt:status_string()`                      [ref][cairo_status_string]
`fopt:merge()`                              [ref][cairo_merge]
`fopt:equal()`                              [ref][cairo_equal]
`fopt:hash()`                               [ref][cairo_hash]
`fopt:set_antialias()`                      [ref][cairo_set_antialias]
`fopt:get_antialias()`                      [ref][cairo_get_antialias]
`fopt:set_subpixel_order()`                 [ref][cairo_set_subpixel_order]
`fopt:get_subpixel_order()`                 [ref][cairo_get_subpixel_order]
`fopt:set_hint_style()`                     [ref][cairo_set_hint_style]
`fopt:get_hint_style()`                     [ref][cairo_get_hint_style]
`fopt:set_hint_metrics()`                   [ref][cairo_set_hint_metrics]
`fopt:get_hint_metrics()`                   [ref][cairo_get_hint_metrics]
`fopt:set_lcd_filter()`                     [ref][cairo_set_lcd_filter]
`fopt:get_lcd_filter()`                     [ref][cairo_get_lcd_filter]
`fopt:set_round_glyph_positions()`          [ref][cairo_set_round_glyph_positions]
`fopt:get_round_glyph_positions()`          [ref][cairo_get_round_glyph_positions]
__regions__
`rgn:create()`                              [ref][cairo_create]
`rgn:create_rectangle()`                    [ref][cairo_create_rectangle]
`rgn:create_rectangles()`                   [ref][cairo_create_rectangles]
`rgn:copy()`                                [ref][cairo_copy]
`rgn:equal()`                               [ref][cairo_equal]
`rgn:status()`                              [ref][cairo_status]
`rgn:status_string()`                       [ref][cairo_status_string]
`rgn:get_extents()`                         [ref][cairo_get_extents]
`rgn:num_rectangles()`                      [ref][cairo_num_rectangles]
`rgn:get_rectangle()`                       [ref][cairo_get_rectangle]
`rgn:is_empty()`                            [ref][cairo_is_empty]
`rgn:contains_rectangle()`                  [ref][cairo_contains_rectangle]
`rgn:contains_point()`                      [ref][cairo_contains_point]
`rgn:translate()`                           [ref][cairo_translate]
`rgn:subtract()`                            [ref][cairo_subtract]
`rgn:subtract_rectangle()`                  [ref][cairo_subtract_rectangle]
`rgn:intersect()`                           [ref][cairo_intersect]
`rgn:intersect_rectangle()`                 [ref][cairo_intersect_rectangle]
`rgn:union()`                               [ref][cairo_union]
`rgn:union_rectangle()`                     [ref][cairo_union_rectangle]
`rgn:xor()`                                 [ref][cairo_xor]
`rgn:xor_rectangle()`                       [ref][cairo_xor_rectangle]
`rgn:reference()`                           [ref][cairo_reference]
`rgn:destroy()`                             [ref][cairo_destroy]
`rgn:free()`                                free (error if ref count > 0)
__paths__
`path:free()`                               [ref][cairo_free]
__rectangles__
`rect:free()`                               [ref][cairo_free]
__glyphs__
`glyph:free()`                              [ref][cairo_free]
__matrices__
`mat:init()`                                [ref][cairo_init]
`mat:init_identity()`                       [ref][cairo_init_identity]
`mat:init_translate()`                      [ref][cairo_init_translate]
`mat:init_scale()`                          [ref][cairo_init_scale]
`mat:init_rotate()`                         [ref][cairo_init_rotate]
`mat:translate()`                           [ref][cairo_translate]
`mat:scale()`                               [ref][cairo_scale]
`mat:rotate()`                              [ref][cairo_rotate]
`mat:rotate_around()`                       [ref][cairo_rotate_around]
`mat:scale_around()`                        [ref][cairo_scale_around]
`mat:invert()`                              [ref][cairo_invert]
`mat:multiply()`                            [ref][cairo_multiply]
`mat:transform_distance()`                  [ref][cairo_transform_distance]
`mat:transform_point()`                     [ref][cairo_transform_point]
`mat:transform()`
`mat:invertible()`
`mat:safe_transform()`
`mat:skew()`
`mat:copy()`
`mat:init_matrix()`
__integer rectangles__
`irect:create_region()`                     [ref][cairo_create_region]
------------------------------------------- ---------------------------------------
</div>


[cairo_save]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-save
[cairo_restore]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-restore
[cairo_push_group]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-push-group
[cairo_push_group_with_content]:           http://cairographics.org/manual/cairo-cairo-t.html#cairo-push-group-with-content
[cairo_pop_group]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group
[cairo_pop_group_to_source]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group-to-source
[cairo_set_operator]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-operator
[cairo_set_source]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source
[cairo_set_source_rgb]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgb
[cairo_set_source_rgba]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgba
[cairo_set_source_surface]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-surface
[cairo_set_tolerance]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-tolerance
[cairo_set_antialias]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-antialias
[cairo_set_fill_rule]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-fill-rule
[cairo_set_line_width]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-width
[cairo_set_line_cap]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-cap
[cairo_set_line_join]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-line-join
[cairo_set_dash]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-dash
[cairo_set_miter_limit]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-miter-limit
[cairo_translate]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-translate
[cairo_scale]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-scale
[cairo_rotate]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-rotate
[cairo_rotate_around]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-rotate-around
[cairo_scale_around]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-scale-around
[cairo_transform]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-transform
[cairo_safe_transform]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-safe-transform
[cairo_set_matrix]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-matrix
[cairo_identity_matrix]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-identity-matrix
[cairo_skew]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-skew
[cairo_user_to_device]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-to-device
[cairo_user_to_device_distance]:           http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-to-device-distance
[cairo_device_to_user]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-device-to-user
[cairo_device_to_user_distance]:           http://cairographics.org/manual/cairo-cairo-t.html#cairo-device-to-user-distance
[cairo_new_path]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-new-path
[cairo_move_to]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-move-to
[cairo_new_sub_path]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-new-sub-path
[cairo_line_to]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-line-to
[cairo_curve_to]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-curve-to
[cairo_quad_curve_to]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-quad-curve-to
[cairo_arc]:                               http://cairographics.org/manual/cairo-cairo-t.html#cairo-arc
[cairo_arc_negative]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-arc-negative
[cairo_circle]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-circle
[cairo_ellipse]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-ellipse
[cairo_rel_move_to]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-rel-move-to
[cairo_rel_line_to]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-rel-line-to
[cairo_rel_curve_to]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-rel-curve-to
[cairo_rel_quad_curve_to]:                 http://cairographics.org/manual/cairo-cairo-t.html#cairo-rel-quad-curve-to
[cairo_rectangle]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-rectangle
[cairo_close_path]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-close-path
[cairo_path_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-path-extents
[cairo_paint]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint
[cairo_paint_with_alpha]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint-with-alpha
[cairo_mask]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-mask
[cairo_mask_surface]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-mask-surface
[cairo_stroke]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke
[cairo_stroke_preserve]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-preserve
[cairo_fill]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill
[cairo_fill_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-preserve
[cairo_copy_page]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-page
[cairo_show_page]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-show-page
[cairo_in_stroke]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-stroke
[cairo_in_fill]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-fill
[cairo_in_clip]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-clip
[cairo_stroke_extents]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-extents
[cairo_fill_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-extents
[cairo_reset_clip]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-reset-clip
[cairo_clip]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip
[cairo_clip_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-preserve
[cairo_clip_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-extents
[cairo_copy_clip_rectangle_list]:          http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-clip-rectangle-list
[cairo_select_font_face]:                  http://cairographics.org/manual/cairo-text.html#cairo-select-font-face
[cairo_set_font_size]:                     http://cairographics.org/manual/cairo-text.html#cairo-set-font-size
[cairo_set_font_matrix]:                   http://cairographics.org/manual/cairo-text.html#cairo-set-font-matrix
[cairo_get_font_matrix]:                   http://cairographics.org/manual/cairo-text.html#cairo-get-font-matrix
[cairo_set_font_options]:                  http://cairographics.org/manual/cairo-text.html#cairo-set-font-options
[cairo_get_font_options]:                  http://cairographics.org/manual/cairo-text.html#cairo-get-font-options
[cairo_set_font_face]:                     http://cairographics.org/manual/cairo-text.html#cairo-set-font-face
[cairo_get_font_face]:                     http://cairographics.org/manual/cairo-text.html#cairo-get-font-face
[cairo_set_scaled_font]:                   http://cairographics.org/manual/cairo-text.html#cairo-set-scaled-font
[cairo_get_scaled_font]:                   http://cairographics.org/manual/cairo-text.html#cairo-get-scaled-font
[cairo_show_text]:                         http://cairographics.org/manual/cairo-text.html#cairo-show-text
[cairo_show_glyphs]:                       http://cairographics.org/manual/cairo-text.html#cairo-show-glyphs
[cairo_show_text_glyphs]:                  http://cairographics.org/manual/cairo-text.html#cairo-show-text-glyphs
[cairo_text_path]:                         http://cairographics.org/manual/cairo-text.html#cairo-text-path
[cairo_glyph_path]:                        http://cairographics.org/manual/cairo-text.html#cairo-glyph-path
[cairo_text_extents]:                      http://cairographics.org/manual/cairo-text.html#cairo-text-extents
[cairo_glyph_extents]:                     http://cairographics.org/manual/cairo-text.html#cairo-glyph-extents
[cairo_font_extents]:                      http://cairographics.org/manual/cairo-text.html#cairo-font-extents
[cairo_get_operator]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-operator
[cairo_get_source]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-source
[cairo_get_tolerance]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-tolerance
[cairo_get_antialias]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-antialias
[cairo_has_current_point]:                 http://cairographics.org/manual/cairo-cairo-t.html#cairo-has-current-point
[cairo_get_current_point]:                 http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-current-point
[cairo_get_fill_rule]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-fill-rule
[cairo_get_line_width]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-width
[cairo_get_line_cap]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-cap
[cairo_get_line_join]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-line-join
[cairo_get_miter_limit]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-miter-limit
[cairo_get_dash_count]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash-count
[cairo_get_dash]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-dash
[cairo_get_matrix]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-matrix
[cairo_get_target]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-target
[cairo_get_group_target]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-group-target
[cairo_copy_path]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-path
[cairo_copy_path_flat]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-path-flat
[cairo_append_path]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-append-path
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data
[cairo_set_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free

[cairo_surface_create_context]:                    http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-create-context
[cairo_surface_create_similar]:                    http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-create-similar
[cairo_surface_create_for_rectangle]:              http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-create-for-rectangle
[cairo_surface_finish]:                            http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-finish
[cairo_surface_get_device]:                        http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-device
[cairo_surface_status]:                            http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-status
[cairo_surface_status_string]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-status-string
[cairo_surface_get_type]:                          http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-type
[cairo_surface_get_content]:                       http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-content
[cairo_surface_write_to_png]:                      http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-write-to-png
[cairo_surface_write_to_png_stream]:               http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-write-to-png-stream
[cairo_surface_get_user_data]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-user-data
[cairo_surface_set_user_data]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-set-user-data
[cairo_surface_get_mime_data]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-mime-data
[cairo_surface_set_mime_data]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-set-mime-data
[cairo_surface_get_font_options]:                  http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-font-options
[cairo_surface_flush]:                             http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-flush
[cairo_surface_mark_dirty]:                        http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-mark-dirty
[cairo_surface_mark_dirty_rectangle]:              http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-mark-dirty-rectangle
[cairo_surface_set_device_offset]:                 http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-set-device-offset
[cairo_surface_get_device_offset]:                 http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-device-offset
[cairo_surface_set_fallback_resolution]:           http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-set-fallback-resolution
[cairo_surface_get_fallback_resolution]:           http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-fallback-resolution
[cairo_surface_copy_page]:                         http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-copy-page
[cairo_surface_show_page]:                         http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-show-page
[cairo_surface_has_show_text_glyphs]:              http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-has-show-text-glyphs
[cairo_surface_create_pattern]:                    http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-create-pattern
[cairo_surface_apply_alpha]:                       http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-apply-alpha
[cairo_surface_reference]:                         http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-reference
[cairo_surface_get_reference_count]:               http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-reference-count
[cairo_surface_destroy]:                           http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-destroy
[cairo_surface_free]:                              http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-free
[cairo_surface_get_image_data]:                    http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-data
[cairo_surface_get_image_format]:                  http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-format
[cairo_surface_get_image_width]:                   http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-width
[cairo_surface_get_image_height]:                  http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-height
[cairo_surface_get_image_stride]:                  http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-stride
[cairo_surface_get_image_bpp]:                     http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-bpp
[cairo_surface_get_image_pixel_function]:          http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-get-image-pixel-function
[cairo_surface_set_image_pixel_function]:          http://cairographics.org/manual/cairo-surface-t.html#cairo-surface-set-image-pixel-function

[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_acquire]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-acquire
[cairo_release]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-release
[cairo_flush]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-flush
[cairo_finish]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-finish
[cairo_get_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data
[cairo_set_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data
[cairo_set_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data
[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_add_color_stop_rgb]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-add-color-stop-rgb
[cairo_add_color_stop_rgba]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-add-color-stop-rgba
[cairo_set_matrix]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-matrix
[cairo_get_matrix]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-matrix
[cairo_set_extend]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-extend
[cairo_get_extend]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-extend
[cairo_set_filter]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-filter
[cairo_get_filter]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-filter
[cairo_get_rgba]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-rgba
[cairo_get_surface]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-surface
[cairo_get_color_stop_rgba]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-color-stop-rgba
[cairo_get_color_stop_count]:              http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-color-stop-count
[cairo_get_linear_points]:                 http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-linear-points
[cairo_get_radial_circles]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-radial-circles
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_get_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data
[cairo_set_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data
[cairo_extents]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-extents
[cairo_text_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-extents
[cairo_glyph_extents]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-glyph-extents
[cairo_text_to_glyphs]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-to-glyphs
[cairo_get_font_face]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-face
[cairo_get_font_matrix]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-matrix
[cairo_get_ctm]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-ctm
[cairo_get_scale_matrix]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-scale-matrix
[cairo_get_font_options]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-options
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_get_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-user-data
[cairo_set_user_data]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-user-data
[cairo_create_scaled_font]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-create-scaled-font
[cairo_toy_get_family]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-toy-get-family
[cairo_toy_get_slant]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-toy-get-slant
[cairo_toy_get_weight]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-toy-get-weight
[cairo_user_set_init_func]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-set-init-func
[cairo_user_set_render_glyph_func]:        http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-set-render-glyph-func
[cairo_user_set_text_to_glyphs_func]:      http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-set-text-to-glyphs-func
[cairo_user_set_unicode_to_glyph_func]:    http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-set-unicode-to-glyph-func
[cairo_user_get_init_func]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-get-init-func
[cairo_user_get_render_glyph_func]:        http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-get-render-glyph-func
[cairo_user_get_text_to_glyphs_func]:      http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-get-text-to-glyphs-func
[cairo_user_get_unicode_to_glyph_func]:    http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-get-unicode-to-glyph-func
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_copy]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_merge]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-merge
[cairo_equal]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-equal
[cairo_hash]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-hash
[cairo_set_antialias]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-antialias
[cairo_get_antialias]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-antialias
[cairo_set_subpixel_order]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-subpixel-order
[cairo_get_subpixel_order]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-subpixel-order
[cairo_set_hint_style]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-hint-style
[cairo_get_hint_style]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-hint-style
[cairo_set_hint_metrics]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-hint-metrics
[cairo_get_hint_metrics]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-hint-metrics
[cairo_set_lcd_filter]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-lcd-filter
[cairo_get_lcd_filter]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-lcd-filter
[cairo_set_round_glyph_positions]:         http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-round-glyph-positions
[cairo_get_round_glyph_positions]:         http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-round-glyph-positions
[cairo_create]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-create
[cairo_create_rectangle]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-create-rectangle
[cairo_create_rectangles]:                 http://cairographics.org/manual/cairo-cairo-t.html#cairo-create-rectangles
[cairo_copy]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy
[cairo_equal]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-equal
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_string]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_extents]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-extents
[cairo_num_rectangles]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-num-rectangles
[cairo_get_rectangle]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-rectangle
[cairo_is_empty]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-is-empty
[cairo_contains_rectangle]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-contains-rectangle
[cairo_contains_point]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-contains-point
[cairo_translate]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-translate
[cairo_subtract]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-subtract
[cairo_subtract_rectangle]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-subtract-rectangle
[cairo_intersect]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-intersect
[cairo_intersect_rectangle]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-intersect-rectangle
[cairo_union]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-union
[cairo_union_rectangle]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-union-rectangle
[cairo_xor]:                               http://cairographics.org/manual/cairo-cairo-t.html#cairo-xor
[cairo_xor_rectangle]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-xor-rectangle
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_init]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-init
[cairo_init_identity]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-init-identity
[cairo_init_translate]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-init-translate
[cairo_init_scale]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-init-scale
[cairo_init_rotate]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-init-rotate
[cairo_translate]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-translate
[cairo_scale]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-scale
[cairo_rotate]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-rotate
[cairo_rotate_around]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-rotate-around
[cairo_scale_around]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-scale-around
[cairo_invert]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-invert
[cairo_multiply]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-multiply
[cairo_transform_distance]:                http://cairographics.org/manual/cairo-cairo-t.html#cairo-transform-distance
[cairo_transform_point]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-transform-point
