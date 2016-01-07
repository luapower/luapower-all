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

--------------------------------------- -----------------------------------------------------
__drawing contexts__
`cr:save()`                             [save state (push to stack)][cairo_save]
`cr:restore()`                          [restore state (pop from stack)][cairo_restore]
`cr:push_group()`                       [ref][cairo_push_group]
`cr:push_group_with_content()`          [ref][cairo_push_group_with_content]
`cr:pop_group()`                        [ref][cairo_pop_group]
`cr:pop_group_to_source()`              [ref][cairo_pop_group_to_source]
`cr:set_operator()`                     [ref][cairo_set_operator]
`cr:set_source()`                       [ref][cairo_set_source]
`cr:set_source_rgb()`                   [ref][cairo_set_source_rgb]
`cr:set_source_rgba()`                  [ref][cairo_set_source_rgba]
`cr:set_source_surface()`               [ref][cairo_set_source_surface]
`cr:set_tolerance()`                    [ref][cairo_set_tolerance]
`cr:set_antialias()`                    [ref][cairo_set_antialias]
`cr:set_fill_rule()`                    [ref][cairo_set_fill_rule]
`cr:set_line_width()`                   [ref][cairo_set_line_width]
`cr:set_line_cap()`                     [ref][cairo_set_line_cap]
`cr:set_line_join()`                    [ref][cairo_set_line_join]
`cr:set_dash()`                         [ref][cairo_set_dash]
`cr:set_miter_limit()`                  [ref][cairo_set_miter_limit]
`cr:translate()`                        [ref][cairo_translate]
`cr:scale()`                            [ref][cairo_scale]
`cr:rotate()`                           [ref][cairo_rotate]
`cr:rotate_around()`                    [ref][cairo_rotate_around]
`cr:scale_around()`                     [ref][cairo_scale_around]
`cr:transform()`                        [ref][cairo_transform]
`cr:safe_transform()`                   [ref][cairo_safe_transform]
`cr:set_matrix()`                       [ref][cairo_set_matrix]
`cr:identity_matrix()`                  [ref][cairo_identity_matrix]
`cr:skew()`                             [ref][cairo_skew]
`cr:user_to_device()`                   [ref][cairo_user_to_device]
`cr:user_to_device_distance()`          [ref][cairo_user_to_device_distance]
`cr:device_to_user()`                   [ref][cairo_device_to_user]
`cr:device_to_user_distance()`          [ref][cairo_device_to_user_distance]
`cr:new_path()`                         [ref][cairo_new_path]
`cr:move_to()`                          [ref][cairo_move_to]
`cr:new_sub_path()`                     [ref][cairo_new_sub_path]
`cr:line_to()`                          [ref][cairo_line_to]
`cr:curve_to()`                         [ref][cairo_curve_to]
`cr:quad_curve_to()`                    [ref][cairo_quad_curve_to]
`cr:arc()`                              [ref][cairo_arc]
`cr:arc_negative()`                     [ref][cairo_arc_negative]
`cr:circle()`                           [ref][cairo_circle]
`cr:ellipse()`                          [ref][cairo_ellipse]
`cr:rel_move_to()`                      [ref][cairo_rel_move_to]
`cr:rel_line_to()`                      [ref][cairo_rel_line_to]
`cr:rel_curve_to()`                     [ref][cairo_rel_curve_to]
`cr:rel_quad_curve_to()`                [ref][cairo_rel_quad_curve_to]
`cr:rectangle()`                        [ref][cairo_rectangle]
`cr:close_path()`                       [ref][cairo_close_path]
`cr:path_extents()`                     [ref][cairo_path_extents]
`cr:paint()`                            [ref][cairo_paint]
`cr:paint_with_alpha()`                 [ref][cairo_paint_with_alpha]
`cr:mask()`                             [ref][cairo_mask]
`cr:mask_surface()`                     [ref][cairo_mask_surface]
`cr:stroke()`                           [ref][cairo_stroke]
`cr:stroke_preserve()`                  [ref][cairo_stroke_preserve]
`cr:fill()`                             [ref][cairo_fill]
`cr:fill_preserve()`                    [ref][cairo_fill_preserve]
`cr:copy_page()`                        [ref][cairo_copy_page]
`cr:show_page()`                        [ref][cairo_show_page]
`cr:in_stroke()`                        [ref][cairo_in_stroke]
`cr:in_fill()`                          [ref][cairo_in_fill]
`cr:in_clip()`                          [ref][cairo_in_clip]
`cr:stroke_extents()`                   [ref][cairo_stroke_extents]
`cr:fill_extents()`                     [ref][cairo_fill_extents]
`cr:reset_clip()`                       [ref][cairo_reset_clip]
`cr:clip()`                             [ref][cairo_clip]
`cr:clip_preserve()`                    [ref][cairo_clip_preserve]
`cr:clip_extents()`                     [ref][cairo_clip_extents]
`cr:copy_clip_rectangle_list()`         [ref][cairo_copy_clip_rectangle_list]
`cr:select_font_face()`                 [ref][cairo_select_font_face]
`cr:set_font_size()`                    [ref][cairo_set_font_size]
`cr:set_font_matrix()`                  [ref][cairo_set_font_matrix]
`cr:get_font_matrix()`                  [ref][cairo_get_font_matrix]
`cr:set_font_options()`                 [ref][cairo_set_font_options]
`cr:get_font_options()`                 [ref][cairo_get_font_options]
`cr:set_font_face()`                    [ref][cairo_set_font_face]
`cr:get_font_face()`                    [ref][cairo_get_font_face]
`cr:set_scaled_font()`                  [ref][cairo_set_scaled_font]
`cr:get_scaled_font()`                  [ref][cairo_get_scaled_font]
`cr:show_text()`                        [ref][cairo_show_text]
`cr:show_glyphs()`                      [ref][cairo_show_glyphs]
`cr:show_text_glyphs()`                 [ref][cairo_show_text_glyphs]
`cr:text_path()`                        [ref][cairo_text_path]
`cr:glyph_path()`                       [ref][cairo_glyph_path]
`cr:text_extents()`                     [ref][cairo_text_extents]
`cr:glyph_extents()`                    [ref][cairo_glyph_extents]
`cr:font_extents()`                     [ref][cairo_font_extents]
`cr:get_operator()`                     [ref][cairo_get_operator]
`cr:get_source()`                       [ref][cairo_get_source]
`cr:get_tolerance()`                    [ref][cairo_get_tolerance]
`cr:get_antialias()`                    [ref][cairo_get_antialias]
`cr:has_current_point()`                [ref][cairo_has_current_point]
`cr:get_current_point()`                [ref][cairo_get_current_point]
`cr:get_fill_rule()`                    [ref][cairo_get_fill_rule]
`cr:get_line_width()`                   [ref][cairo_get_line_width]
`cr:get_line_cap()`                     [ref][cairo_get_line_cap]
`cr:get_line_join()`                    [ref][cairo_get_line_join]
`cr:get_miter_limit()`                  [ref][cairo_get_miter_limit]
`cr:get_dash_count()`                   [ref][cairo_get_dash_count]
`cr:get_dash()`                         [ref][cairo_get_dash]
`cr:get_matrix()`                       [ref][cairo_get_matrix]
`cr:get_target()`                       [ref][cairo_get_target]
`cr:get_group_target()`                 [ref][cairo_get_group_target]
`cr:copy_path()`                        [ref][cairo_copy_path]
`cr:copy_path_flat()`                   [ref][cairo_copy_path_flat]
`cr:append_path()`                      [ref][cairo_append_path]
`cr:status()`                           [ref][cairo_status]
`cr:status_string()`                    [ref][cairo_status_string]
`cr:get_user_data(key)`                 [ref][cairo_get_user_data]
`cr:set_user_data(key, val[, destroy])` [ref][cairo_set_user_data]
`cr:reference()`                        [ref][cairo_reference]
`cr:get_reference_count()`              [ref][cairo_get_reference_count]
`cr:destroy()`                          [ref][cairo_destroy]
`cr:free()`                             [ref][cairo_free]
__surfaces__
`sr:create_context()`
`sr:create_similar()`
`sr:create_for_rectangle()`
`sr:finish()`
`sr:get_device()`
`sr:status()`
`sr:status_string()`
`sr:get_type()`
`sr:get_content()`
`sr:write_to_png()`
`sr:write_to_png_stream()`
`sr:get_user_data()`
`sr:set_user_data()`
`sr:get_mime_data()`
`sr:set_mime_data()`
`sr:get_font_options()`
`sr:flush()`
`sr:mark_dirty()`
`sr:mark_dirty_rectangle()`
`sr:set_device_offset()`
`sr:get_device_offset()`
`sr:set_fallback_resolution()`
`sr:get_fallback_resolution()`
`sr:copy_page()`
`sr:show_page()`
`sr:has_show_text_glyphs()`
`sr:create_pattern()`
`sr:apply_alpha()`
`sr:reference()`
`sr:get_reference_count()`
`sr:destroy()`
`sr:free()`
__image surfaces__
`sr:get_image_data()`
`sr:get_image_format()`
`sr:get_image_width()`
`sr:get_image_height()`
`sr:get_image_stride()`
`sr:get_image_bpp()`
`sr:get_image_pixel_function()`
`sr:set_image_pixel_function()`
__devices__
`dev:get_type()`
`dev:status()`
`dev:status_string()`
`dev:acquire()`
`dev:release()`
`dev:flush()`
`dev:finish()`
`dev:get_user_data()`
`dev:set_user_data()`
`dev:reference()`
`dev:get_reference_count()`
`dev:destroy()`
`dev:free()`
__patterns__
`patt:status()`
`patt:status_string()`
`patt:get_user_data()`
`patt:set_user_data()`
`patt:get_type()`
`patt:add_color_stop_rgb()`
`patt:add_color_stop_rgba()`
`patt:set_matrix()`
`patt:get_matrix()`
`patt:set_extend()`
`patt:get_extend()`
`patt:set_filter()`
`patt:get_filter()`
`patt:get_rgba()`
`patt:get_surface()`
`patt:get_color_stop_rgba()`
`patt:get_color_stop_count()`
`patt:get_linear_points()`
`patt:get_radial_circles()`
`patt:reference()`
`patt:get_reference_count()`
`patt:destroy()`
`patt:free()`
__scaled fonts__
`sfont:status()`
`sfont:status_string()`
`sfont:get_type()`
`sfont:get_user_data()`
`sfont:set_user_data()`
`sfont:extents()`
`sfont:text_extents()`
`sfont:glyph_extents()`
`sfont:text_to_glyphs()`
`sfont:get_font_face()`
`sfont:get_font_matrix()`
`sfont:get_ctm()`
`sfont:get_scale_matrix()`
`sfont:get_font_options()`
`sfont:reference()`
`sfont:get_reference_count()`
`sfont:destroy()`
`sfont:free()`
__font faces__
`font:status()`
`font:status_string()`
`font:get_type()`
`font:get_user_data()`
`font:set_user_data()`
`font:create_scaled_font()`
`font:toy_get_family()`
`font:toy_get_slant()`
`font:toy_get_weight()`
`font:user_set_init_func()`
`font:user_set_render_glyph_func()`
`font:user_set_text_to_glyphs_func()`
`font:user_set_unicode_to_glyph_func()`
`font:user_get_init_func()`
`font:user_get_render_glyph_func()`
`font:user_get_text_to_glyphs_func()`
`font:user_get_unicode_to_glyph_func()`
`font:reference()`
`font:get_reference_count()`
`font:destroy()`
`font:free()`
__font options__
`fopt:copy()`
`fopt:free()`
`fopt:status()`
`fopt:status_string()`
`fopt:merge()`
`fopt:equal()`
`fopt:hash()`
`fopt:set_antialias()`
`fopt:get_antialias()`
`fopt:set_subpixel_order()`
`fopt:get_subpixel_order()`
`fopt:set_hint_style()`
`fopt:get_hint_style()`
`fopt:set_hint_metrics()`
`fopt:get_hint_metrics()`
--private functions, only available in our custom build
`fopt:set_lcd_filter()`
`fopt:get_lcd_filter()`
`fopt:set_round_glyph_positions()`
`fopt:get_round_glyph_positions()`
__regions__
`rgn:create()`
`rgn:create_rectangle()`
`rgn:create_rectangles()`
`rgn:copy()`
`rgn:equal()`
`rgn:status()`
`rgn:status_string()`
`rgn:get_extents()`
`rgn:num_rectangles()`
`rgn:get_rectangle()`
`rgn:is_empty()`
`rgn:contains_rectangle()`
`rgn:contains_point()`
`rgn:translate()`
`rgn:subtract()`
`rgn:subtract_rectangle()`
`rgn:intersect()`
`rgn:intersect_rectangle()`
`rgn:union()`
`rgn:union_rectangle()`
`rgn:xor()`
`rgn:xor_rectangle()`
`rgn:reference()`
`rgn:destroy()`
`rgn:free()`
__paths__
`path:free()`
__rectangles__
`rect:free()`
__glyphs__
`glyph:free()`
__matrices__
`mat:init()`
`mat:init_identity()`
`mat:init_translate()`
`mat:init_scale()`
`mat:init_rotate()`
`mat:translate()`
`mat:scale()`
`mat:rotate()`
`mat:rotate_around()`
`mat:scale_around()`
`mat:invert()`
`mat:multiply()`
`mat:transform_distance()`
`mat:transform_point()`
`mat:--additions`
`mat:transform()`
`mat:invertible()`
`mat:safe_transform()`
`mat:skew()`
`mat:copy()`
`mat:init_matrix()`
__integer rectangles__
`irect:create_region()`
--------------------------------------- ---------------------------------------



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
[cairo_select_font_face]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-select-font-face
[cairo_set_font_size]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-font-size
[cairo_set_font_matrix]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-font-matrix
[cairo_get_font_matrix]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-matrix
[cairo_set_font_options]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-font-options
[cairo_get_font_options]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-options
[cairo_set_font_face]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-font-face
[cairo_get_font_face]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-face
[cairo_set_scaled_font]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-scaled-font
[cairo_get_scaled_font]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-scaled-font
[cairo_show_text]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-show-text
[cairo_show_glyphs]:                       http://cairographics.org/manual/cairo-cairo-t.html#cairo-show-glyphs
[cairo_show_text_glyphs]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-show-text-glyphs
[cairo_text_path]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-path
[cairo_glyph_path]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-glyph-path
[cairo_text_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-extents
[cairo_glyph_extents]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-glyph-extents
[cairo_font_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-font-extents
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
