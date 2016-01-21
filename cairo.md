---
tagline: cairo graphics engine
---

## `local cairo = require'cairo'`

A lightweight ffi binding of the [cairo graphics] library.

[cairo graphics]:   http://cairographics.org/

## API

__NOTE:__ In the table below, `foo([val]) /-> val` is a shortcut for saying
that `foo(val)` sets the value of foo and `foo() -> val` gets it.

__NOTE:__ flags can be passed as lowercase strings without prefix eg.
pass 'argb32' for `C.CAIRO_FORMAT_ARGB32` in `cairo.image_surface()`.

<div class="small">
------------------------------------------------------------------- -------------------------------------------------------------------
__pixman surfaces__
`cairo.image_surface(fmt, w, h) -> sr`                              [create a pixman surface][cairo_image_surface_create]
`cairo.image_surface(bmp) -> sr`                                    [create a pixman surface given a][cairo_image_surface_create_for_data] [bitmap] (1)
`sr:bitmap() -> bmp`                                                get the image surface as a [bitmap]
`sr:data() -> data`                                                 [get the image surface pixel buffer][cairo_image_surface_get_data]
`sr:format() -> fmt`                                                [get the image surface format][cairo_image_surface_get_format]
`sr:bitmap_format() -> fmt`                                         get the image surface [bitmap] format
`sr:width() -> w`                                                   [get the image surface width][cairo_image_surface_get_width]
`sr:height() -> h`                                                  [get the image surface height][cairo_image_surface_get_height]
`sr:stride() -> stride`                                             [get the image surface stride][cairo_image_surface_get_stride]
`sr:bpp() -> bpp`                                                   get the image surface bits-per-pixel
__surfaces__
`sr:sub(x, y, w, h) -> sr`                                          [create a sub-surface][cairo_surface_create_for_rectangle]
`sr:similar_surface(content, w, h) -> sr`                           [create a similar surface][cairo_surface_create_similar]
`sr:similar_image_surface(fmt, w, h) -> sr`                         [create a similar image surface][cairo_surface_create_similar_image]
`sr:type() -> type`                                                 [get surface type][cairo_surface_get_type]
`sr:content() -> content`                                           [get surface content type][cairo_surface_get_content]
`sr:flush()`                                                        [perform any pending drawing commands][cairo_surface_flush]
`sr:mark_dirty([x, y, w, h])`                                       [re-read any cached areas of (parts of) the surface][cairo_surface_mark_dirty]
`sr:fallback_resolution([xppi, yppi]) /-> xppi, yppi`               [get/set fallback resolution][cairo_surface_set_fallback_resolution]
`sr:has_show_text_glyphs() -> t|f`                                  [check if surface supports cairo_show_text_glyphs() for realz][cairo_surface_has_show_text_glyphs]
`sr:mime_data(type[, data, len[, destroy[, arg]]]) /-> data, len`   [get/set mime data][cairo_surface_set_mime_data]
`sr:supports_mime_type(type) -> t|f`                                [check if the surface supports a mime type][cairo_surface_supports_mime_type]
`sr:map_to_image([x, y, w, h]) -> image_sr`                         [get an image surface for modifying the backing store][cairo_surface_map_to_image]
`sr:unmap_image(image_sr)`                                          [upload image to backing store and unmap][cairo_surface_unmap_image]
`sr:finish()`                                                       [finish the surface][cairo_surface_finish]
`sr:apply_alpha(a)`                                                 make the surface transparent
__recording surfaces__
`cairo.recording_surface(content[, x, y, w, h])`                    [create a recording surface][cairo_recording_surface_create]
`sr:ink_extents() -> x, y, w, h`                                    [get recording surface ink extents][cairo_recording_surface_ink_extents]
`sr:recording_extents() -> x, y, w, h | nil`                        [get recording surface extents][cairo_recording_surface_get_extents]
__png support__
`cairo.image_surface_from_png(filename) -> sr`                      [create a pixman surface from a png file][cairo_image_surface_create_from_png]
`cairo.image_surface_from_png_stream(read_func, arg) -> sr`         [create a pixman surface from a png stream][cairo_image_surface_create_from_png_stream]
`sr:write_to_png(filename) -> true | nil,err,status`                [write surface to png file][cairo_surface_write_to_png]
`sr:write_to_png_stream(write_func, arg) -> true | nil,err,status`  [write surface to png stream][cairo_surface_write_to_png_stream]
__drawing contexts__
`sr:context() -> cr`                                                [create a drawing context on a surface][cairo_create]
`cr:save()`                                                         [save state (push to stack)][cairo_save]
`cr:restore()`                                                      [restore state (pop from stack)][cairo_restore]
__sources__
`cr:rgb(r, g, b)`                                                   [set a RGB color as source][cairo_set_source_rgb]
`cr:rgba(r, g, b, a)`                                               [set a RGBA color as source][cairo_set_source_rgba]
`cr:source([patt | sr, [x, y]]) /-> patt`                           [get/set a pattern or surface as source][cairo_set_source]
`cr:operator([operator]) /-> operator`                              [get/set the compositing operator][cairo_set_operator]
`cr:mask(patt | sr[, x, y])`                                        [draw using a pattern's (or surface's) alpha channel as a mask][cairo_mask]
__groups__
`cr:push_group([content])`                                          [redirect drawing to an intermediate surface][cairo_push_group]
`cr:pop_group() -> patt`                                            [terminate the redirection and return it as pattern][cairo_pop_group]
`cr:pop_group_to_source()`                                          [terminate the redirection and install it as pattern][cairo_pop_group_to_source]
__transformations__
`cr:translate(x, y)`                                                [translate the user-space origin][cairo_translate]
`cr:scale(sx, sy)`                                                  [scale the user-space][cairo_scale]
`cr:scale_around(cx, cy, sx, sy)`                                   scale the user-space arount a point
`cr:rotate(angle)`                                                  [rotate the user-space][cairo_rotate]
`cr:rotate_around(cx, cy, angle)`                                   rotate the user-space around a point
`cr:skew(ax, ay)`                                                   skew the user-space
`cr:transform(mt)`                                                  [transform the user-space][cairo_transform]
`cr:safe_transform(mt)`                                             transform the user-space if the matrix is invertible
`cr:matrix([mt]) /-> mt`                                            [get/set the CTM][cairo_set_matrix]
`cr:identity_matrix()`                                              [reset the CTM][cairo_identity_matrix]
__paths__
`cr:new_path()`                                                     [create path][cairo_new_path]
`cr:new_sub_path()`                                                 [create sub-path][cairo_new_sub_path]
`cr:move_to(x, y)`                                                  [move the current point][cairo_move_to]
`cr:line_to(x, y)`                                                  [add a line to the current path][cairo_line_to]
`cr:curve_to(x1, y1, x2, y2, x3, y3)`                               [add a cubic bezier to the current path][cairo_curve_to]
`cr:quad_curve_to(x1, y1, x2, y2)`                                  add a quad bezier to the current path
`cr:arc(cx, cy, r, a1, a2)`                                         [add an arc to the current path][cairo_arc]
`cr:arc_negative(cx, cy, r, a1, a2)`                                [add a negative arc to the current path][cairo_arc_negative]
`cr:circle(cx, cy, r)`                                              add a circle to the current path
`cr:ellipse(cx, cy, rx, ry, rotation)`                              add an ellipse to the current path
`cr:rel_move_to(x, y)`                                              [move the current point][cairo_rel_move_to]
`cr:rel_line_to(x, y)`                                              [add a line to the current path][cairo_rel_line_to]
`cr:rel_curve_to(x1, y1, x2, y2, x3, y3)`                           [add a cubic bezier to the current path][cairo_rel_curve_to]
`cr:rel_quad_curve_to(x1, y1, x2, y2)`                              add a quad bezier to the current path
`cr:rectangle(x, y, w, h)`                                          [add a rectangle to the current path][cairo_rectangle]
`cr:close_path()`                                                   [close current path][cairo_close_path]
`cr:copy_path() -> path`                                            [copy current path to a path object][cairo_copy_path]
`cr:copy_path_flat() -> path`                                       [copy current path flattened][cairo_copy_path_flat]
`cr:append_path(path)`                                              [append a path to current path][cairo_append_path]
`cr:path_extents() -> x1, y1, x2, y2`                               [get the bouding box of the current path][cairo_path_extents]
`cr:current_point() -> x, y`                                        [get the current point][cairo_get_current_point]
`cr:has_current_point() -> t|f`                                     [check if there's a current point][cairo_has_current_point]
__filling and stroking__
`cr:paint()`                                                        [paint the current source within the current clipping region][cairo_paint]
`cr:paint_with_alpha(alpha)`                                        [paint the current source with transparency][cairo_paint_with_alpha]
`cr:stroke()`                                                       [stroke the current path and discard it][cairo_stroke]
`cr:stroke_preserve()`                                              [stroke and keep the path][cairo_stroke_preserve]
`cr:fill()`                                                         [fill the current path and discard it][cairo_fill]
`cr:fill_preserve()`                                                [fill and keep the path][cairo_fill_preserve]
`cr:in_stroke(x, y) -> t|f`                                         [hit-test the stroke area][cairo_in_stroke]
`cr:in_fill(x, y) -> t|f`                                           [hit-test the fill area][cairo_in_fill]
`cr:in_clip(x, y) -> t|f`                                           [hit-test the clip area][cairo_in_clip]
`cr:stroke_extents() -> x1, y1, x2, y2`                             [get the bounding box of stroking the current path][cairo_stroke_extents]
`cr:fill_extents() -> x1, y1, x2, y2`                               [get the bounding box of filling the current path][cairo_fill_extents]
__clipping__
`cr:clip()`                                                         [intersect the current path to the current clipping region and discard the path][cairo_clip]
`cr:clip_preserve()`                                                [clip and keep the current path][cairo_clip_preserve]
`cr:reset_clip()`                                                   [remove all clipping][cairo_reset_clip]
`cr:clip_extents() -> x1, y1, x2, y2`                               [get the clip extents][cairo_clip_extents]
`cr:clip_rectangles() -> rlist`                                     [get the clipping rectangles][cairo_copy_clip_rectangle_list]
__patterns__
`patt:type() -> type`                                               [get the pattern type][cairo_pattern_get_type]
`patt:matrix([mt]) /-> mt`                                          [get/set the matrix][cairo_pattern_set_matrix]
`patt:extend([extend]) /-> extend`                                  [get/set the extend][cairo_pattern_set_extend]
`patt:filter([filter]) /-> filter`                                  [get/set the filter][cairo_pattern_set_filter]
`patt:surface() -> sr | nil`                                        [get the pattern's surface][cairo_pattern_get_surface]
__solid-color patterns__
`cairo.rgb_pattern(r, g, b) -> patt`                                [create a matte color pattern][cairo_pattern_create_rgb]
`cairo.rgba_pattern(r, g, b, a) -> patt`                            [create a transparent color pattern][cairo_pattern_create_rgba]
`patt:rgba() -> r, g, b, a`                                         [get the color of a solid color pattern][cairo_pattern_get_rgba]
__gradient patterns__
`cairo.linear_pattern(x0, y0, x1, y1) -> patt`                      [create a linear gradient][cairo_pattern_create_linear]
`cairo.radial_pattern(cx0, cy0, r0, cx1, cy1, r1) -> patt`          [create a radial gradient][cairo_pattern_create_radial]
`patt:linear_points() -> x0, y0, x1, y1`                            [get the endpoints of a linear gradient][cairo_pattern_get_linear_points]
`patt:radial_circles() -> cx0, cy0, r0, cx1, cy1, r1`               [get the circles of radial gradient][cairo_pattern_get_radial_circles]
`patt:add_color_stop_rgb(offset, r, g, b)`                          [add a RGB color stop][cairo_pattern_add_color_stop_rgb]
`patt:add_color_stop_rgba(offset, r, g, b, a)`                      [add a RGBA color stop][cairo_pattern_add_color_stop_rgba]
`patt:color_stop_count() -> n`                                      [get the number of color stops][cairo_pattern_get_color_stop_count]
`patt:color_stop_rgba(i) -> offset, r, g, b, a`                     [get a color stop][cairo_pattern_get_color_stop_rgba]
__surface patterns__
`cairo.surface_pattern(sr) -> patt`                                 [create a surface-type pattern][cairo_pattern_create_for_surface]
__raster-source patterns__
`cairo.raster_source_pattern(data, content, w, h) -> patt`          [create a raster source-type pattern][cairo_pattern_create_raster_source]
`patt:callback_data([data]) /-> data`                               [get/set callback data][cairo_raster_source_pattern_set_callback_data]
`patt:acquire_function([func]) /-> func`                            [get/set the acquire function][cairo_raster_source_pattern_set_acquire]
`patt:snapshot_function([func]) /-> func`                           [get/set the snapshot function][cairo_raster_source_pattern_set_snapshot]
`patt:copy_function([func]) /-> func`                               [get/set the copy function][cairo_raster_source_pattern_set_copy]
`patt:finish_function([func]) /-> func`                             [get/set the finish function][cairo_raster_source_pattern_set_finish]
__mesh patterns__
`cairo.mesh_pattern() -> patt`                                      [create a mesh pattern][cairo_pattern_create_mesh]
`patt:begin_patch()`                                                [start a patch][cairo_mesh_pattern_begin_patch]
`patt:end_patch()`                                                  [end a patch][cairo_mesh_pattern_end_patch]
__fonts and text__
`cr:select_font_face(family, slant, weight)`                        [select a font face][cairo_select_font_face]
`cr:font_size(size)`                                                [set font size][cairo_set_font_size]
`cr:font_matrix([mt]) /-> mt`                                       [get/set font matrix][cairo_set_font_matrix]
`cr:show_text(s)`                                                   [show text][cairo_show_text]
`cr:show_glyphs(glyphs, #glyphs)`                                   [show glyphs][cairo_show_glyphs]
`cr:show_text_glyphs(s, #s, gs, #gs, cs, #cs, f)`                   [show text glyphs][cairo_show_text_glyphs]
`cr:text_path(s)`                                                   [ref][cairo_text_path]
`cr:glyph_path(glyphs, #glyphs)`                                    [ref][cairo_glyph_path]
`cr:text_extents(s) -> cairo_text_extents_t`                        [get text extents][cairo_text_extents]
`cr:glyph_extents(glyphs, #glyphs) -> cairo_text_extents_t`         [ref][cairo_glyph_extents]
`cr:font_extents() -> cairo_font_extents_t`                         [ref][cairo_font_extents]
__font faces__
`cr:font_face([face]) /-> face`                                     [get/set font face][cairo_set_font_face]
`face:type() -> type`                                               [ref][cairo_font_face_get_type]
`face:family() -> s`                                                [ref][cairo_font_face_toy_get_family]
`face:slant() -> cairo_font_slant_t`                                [ref][cairo_font_face_toy_get_slant]
`face:weight() -> cairo_font_weight_t`                              [ref][cairo_font_face_toy_get_weight]
__callback-based fonts__
`cairo.user_font_face() -> face`                                    [ref][cairo_user_font_face_create]
`face:init_func(func)`                                              [ref][cairo_font_face_user_set_init_func]
`face:render_glyph_func(func)`                                      [ref][cairo_font_face_user_set_render_glyph_func]
`face:text_to_glyphs_func(func)`                                    [ref][cairo_font_face_user_set_text_to_glyphs_func]
`face:unicode_to_glyph_func(func)`                                  [ref][cairo_font_face_user_set_unicode_to_glyph_func]
`cairo.toy_font_face(family, slant, weight) -> face`                [ref][cairo_toy_font_face_create]
`sfont:font_face() -> face`                                         [ref][cairo_scaled_font_get_font_face]
__scaled fonts__
`face:scaled_font(mt, ctm, fopt) -> sfont`                          [create scaled font][cairo_font_face_create_scaled_font]
`cr:scaled_font([sfont]) /-> sfont`                                 [get/set scaled font][cairo_set_scaled_font]
`sfont:type() -> cairo_font_type_t`                                 [ref][cairo_scaled_font_get_type]
`sfont:extents() -> cairo_text_extents_t`                           [ref][cairo_scaled_font_extents]
`sfont:text_extents(s) -> cairo_text_extents_t`                     [ref][cairo_scaled_font_text_extents]
`sfont:glyph_extents(glyphs, #glyphs) -> cairo_text_extents_t`      [ref][cairo_scaled_font_glyph_extents]
`sfont:text_to_glyphs(x, y, s, #s, gs, #gs, cs, #cs, cf) -> status` [ref][cairo_scaled_font_text_to_glyphs]
`sfont:font_matrix() -> mt`                                         [ref][cairo_scaled_font_get_font_matrix]
`sfont:ctm()`                                                       [ref][cairo_scaled_font_get_ctm]
`sfont:scale_matrix()`                                              [ref][cairo_scaled_font_get_scale_matrix]
`sfont:font_options([fopt]) /-> fopt`                               [get scaled font options][cairo_scaled_font_get_font_options]
__rasterization options__
`cr:tolerance([tolerance]) /-> tolerance`                           [get/set tolerance][cairo_get_tolerance]
`cr:antialias([antialias]) /-> antialias`                           [set the antialiasing mode][cairo_set_antialias]
`cr:fill_rule([rule]) /-> rule`                                     [set the fill rule][cairo_set_fill_rule]
`cr:line_width([width]) /-> width`                                  [set the current line width][cairo_set_line_width]
`cr:line_cap([cap]) /-> cap`                                        [set the current line cap][cairo_set_line_cap]
`cr:line_join([join]) /-> join`                                     [set the current line join][cairo_set_line_join]
`cr:dash([dashes[, offset]]) /-> dashes, dash_count`                [set the dash pattern for cairo_stroke()][cairo_set_dash]
`cr:dash_count() -> n`                                              [ref][cairo_get_dash_count]
`cr:miter_limit([limit]) /-> limit`                                 [set the current miter limit][cairo_set_miter_limit]
__device-space__
`cr:user_to_device(x, y) -> x, y`                                   [user to device (point)][cairo_user_to_device]
`cr:user_to_device_distance(x, y) -> x, y`                          [user to device (distance)][cairo_user_to_device_distance]
`cr:device_to_user(x, y) -> x, y`                                   [device to user (point)][cairo_device_to_user]
`cr:device_to_user_distance(x, y) -> x, y`                          [device to user (distance)][cairo_device_to_user_distance]
__glyphs__
`cairo.allocate_glyphs(num_glyphs) -> glyphs`                       [allocate an array of glyphs][cairo_glyph_allocate]
__text clusters__
`cairo.allocate_text_clusters(num_clusters) -> clusters`            [allocate an array of text clusters][cairo_text_cluster_allocate]
__font options__
`cairo.font_options() -> fopt`                                      [create a font options object][cairo_font_options_create]
`fopt:copy() -> fopt`                                               [copy font options][cairo_font_options_copy]
`fopt:merge(fopt)`                                                  [merge options][cairo_font_options_merge]
`fopt:equal(fopt) -> t|f`                                           [compare options (also with `==`)][cairo_font_options_equal]
`fopt:hash() -> n`                                                  [get options hash][cairo_font_options_hash]
`fopt:antialias([antialias]) /-> antialias`                                     [set antialias][cairo_font_options_set_antialias]
`fopt:subpixel_order([order]) /-> order`                            [get/set subpixel order][cairo_font_options_set_subpixel_order]
`fopt:hint_style([style]) /-> style`                                [get/set hint style][cairo_font_options_set_hint_style]
`fopt:hint_metrics([metrics]) /-> metrics`                          [get/set hint metrics][cairo_font_options_set_hint_metrics]
`fopt:lcd_filter([filter]) /-> filter`                              [get/set lcd filter][cairo_font_options_set_lcd_filter]
`fopt:round_glyph_positions([pos]) /-> pos`                         [get/set round glyph positions][cairo_font_options_set_round_glyph_positions]
`sr:font_options([fopt]) /-> fopt`                                  [get/set surface font options][cairo_surface_get_font_options]
`cr:font_options([fopt]) /-> fopt`                                  [get/set font options][cairo_set_font_options]
__multi-page backends__
`sr:copy_page()`                                                    [emit the current page and retain surface contents][cairo_surface_copy_page]
`sr:show_page()`                                                    [emit the current page and clear surface contents][cairo_surface_show_page]
__targets__
`cr:target() -> sr`                                                 [get the ultimate destination surface][cairo_get_target]
`cr:group_target() -> sr`                                           [get the current destination surface][cairo_get_group_target]
__devices__
`sr:device() -> cairo_device_t`                                     [get the device of the surface][cairo_surface_get_device]
`sr:device_offset([x, y]) /-> x, y`                                 [set device offset][cairo_surface_set_device_offset]
`dev:type() -> type`                                                [ref][cairo_get_type]
`dev:acquire() -> status`                                           [ref][cairo_acquire]
`dev:release()`                                                     [ref][cairo_release]
`dev:flush()`                                                       [ref][cairo_flush]
`dev:finish()`                                                      [ref][cairo_finish]
__matrices__
`mat:init()`                                                        [ref][cairo_matrix_init]
`mat:init_identity()`                                               [ref][cairo_matrix_init_identity]
`mat:init_translate()`                                              [ref][cairo_matrix_init_translate]
`mat:init_scale()`                                                  [ref][cairo_matrix_init_scale]
`mat:init_rotate()`                                                 [ref][cairo_matrix_init_rotate]
`mat:translate(x, y)`                                               [ref][cairo_matrix_translate]
`mat:scale(sx, sy)`                                                 [ref][cairo_matrix_scale]
`mat:rotate(angle)`                                                 [ref][cairo_matrix_rotate]
`mat:rotate_around(cx, cy, angle)`                                  [ref][cairo_matrix_rotate_around]
`mat:scale_around(cx, cy, sx, sy)`                                  [ref][cairo_matrix_scale_around]
`mat:invert()`                                                      [ref][cairo_matrix_invert]
`mat:multiply()`                                                    [ref][cairo_matrix_multiply]
`mat:transform_point(x, y) -> x, y`                                 [ref][cairo_matrix_transform_point]
`mat:transform_distance(x, y) -> x, y`                              [ref][cairo_matrix_transform_distance]
`mat:transform(mat)`
`mat:invertible() -> t|f`
`mat:safe_transform(mat)`
`mat:skew(ay, ay)`
`mat:copy() -> mat`                                                 copy matrix
`mat:init_matrix(mat)`                                              init with a matrix
__regions__
`cairo.region([[x, y, w, h] | rlist]) -> rgn`                       [ref][cairo_region_create]
`rgn:copy() -> rgn`                                                 [copy region][cairo_region_copy]
`rgn:equal(rgn) -> t|f`                                             [compare regions][cairo_region_equal]
`rgn:extents() -> x, y, w, h`                                       [region extents][cairo_region_get_extents]
`rgn:num_rectangles() -> n`                                         [number of rectangles][cairo_region_num_rectangles]
`rgn:rectangle(i) -> x, y, w, h`                                    [get a rectangle][cairo_region_get_rectangle]
`rgn:is_empty() -> t|f`                                             [check if empty][cairo_region_is_empty]
`rgn:contains_rectangle(x, y, w, h) -> t|f | 'partial'`             [rectangle hit test][cairo_region_contains_rectangle]
`rgn:contains_point(x, y) -> t|f`                                   [point hit test][cairo_region_contains_point]
`rgn:translate(x, y)`                                               [translate region][cairo_region_translate]
`rgn:subtract(rgn | x, y, w, h)`                                    [substract region or rectangle][cairo_region_subtract]
`rgn:intersect(rgn | x, y, w, h)`                                   [intersect with region or rectangle][cairo_region_intersect]
`rgn:union(rgn | x, y, w, h)`                                       [union with region or rectangle][cairo_region_union]
`rgn:xor(rgn | x, y, w, h)`                                         [xor with region or rectangle][cairo_region_xor]
__memory management__
`obj:free()`                                                        [free object][cairo_destroy]
`obj:refcount() -> refcount`                                        [get ref count (*)][cairo_get_reference_count]
`obj:ref()`                                                         [increase ref count (*)][cairo_reference]
`obj:unref()`                                                       [decrease ref count and free when 0 (*)][cairo_destroy]
__object status__
`obj:status() -> status`                                            [get status][cairo_status_t]
`obj:status_message() -> s`                                         [get status message][cairo_status_to_string]
`obj:check()`                                                       raise an error if the object has an error status
__misc.__
`cairo.stride(fmt, w) -> stride`                                    [get stride for a format and width][cairo_format_stride_for_width]
`cairo.bitmap_format(cairo_fmt) -> bmp_fmt`                         get the [bitmap] format corresponding to a cairo format
`cairo.cairo_format(bmp_fmt) -> cairo_fmt`                          get the cairo format corresponding to a bitmap format
`cairo.version() -> n`                                              [get lib version][cairo_version]
`cairo.version_string() -> s`                                       [get lib version as "X.Y.Z"][cairo_version_string]
------------------------------------------------------------------- -------------------------------------------------------------------
</div>

> (1) supported formats: 'bgra8', 'bgrx8', 'g8', 'g1', 'rgb565'.
> (*) for ref-counted objects only: `cr`, `sr`, `dev`, `patt`, `sfont`, `font` and `rgn`.


## Binaries

The included binaries are built with support for in-memory (pixman) surfaces,
recording surfaces, ps surfaces, pdf surfaces, svg surfaces, win32 surfaces,
win32 fonts and freetype fonts.


[cairo_image_surface_create]:              http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create
[cairo_image_surface_create_for_data]:     http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create-for-data
[cairo_image_surface_get_data]:            http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-data
[cairo_image_surface_get_format]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-format
[cairo_image_surface_get_width]:           http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-width
[cairo_image_surface_get_height]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-height
[cairo_image_surface_get_stride]:          http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-stride

[cairo_surface_create_for_rectangle]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-for-rectangle
[cairo_surface_create_similar]:            http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar
[cairo_surface_create_similar_image]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar-image
[cairo_surface_get_type]:                  http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-type
[cairo_surface_get_content]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-content
[cairo_surface_flush]:                     http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-flush
[cairo_surface_mark_dirty]:                http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-mark-dirty
[cairo_surface_set_fallback_resolution]:   http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-fallback-resolution
[cairo_surface_has_show_text_glyphs]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-has-show-text-glyphs
[cairo_surface_set_mime_data]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-mime-data
[cairo_surface_supports_mime_type]:        http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-supports-mime-type
[cairo_surface_map_to_image]:              http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-map-to-image
[cairo_surface_unmap_image]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-unmap-image
[cairo_surface_finish]:                    http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-finish

[cairo_recording_surface_create]:          http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-create
[cairo_recording_surface_ink_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-ink-extents
[cairo_recording_surface_get_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-get-extents

[cairo_image_surface_create_from_png]:           http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png
[cairo_image_surface_create_from_png_stream]:    http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png-stream
[cairo_surface_write_to_png]:                    http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png
[cairo_surface_write_to_png_stream]:             http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png-stream

[cairo_create]:                            http://cairographics.org/manual/cairo-t.html#cairo-create
[cairo_save]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-save
[cairo_restore]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-restore

[cairo_set_source_rgb]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgb
[cairo_set_source_rgba]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source-rgba
[cairo_set_source]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-source
[cairo_set_operator]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-set-operator
[cairo_mask]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-mask

[cairo_push_group]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-push-group
[cairo_pop_group]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group
[cairo_pop_group_to_source]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-pop-group-to-source

[cairo_translate]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-translate
[cairo_scale]:                             http://cairographics.org/manual/cairo-Transformations.html#cairo-scale
[cairo_scale_around]:                      http://cairographics.org/manual/cairo-Transformations.html#cairo-scale-around
[cairo_rotate]:                            http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate
[cairo_rotate_around]:                     http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate-around
[cairo_skew]:                              http://cairographics.org/manual/cairo-Transformations.html#cairo-skew
[cairo_transform]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-transform
[cairo_set_matrix]:                        http://cairographics.org/manual/cairo-Transformations.html#cairo-set-matrix
[cairo_identity_matrix]:                   http://cairographics.org/manual/cairo-Transformations.html#cairo-identity-matrix

[cairo_new_path]:                          http://cairographics.org/manual/cairo-Paths.html#cairo-new-path
[cairo_new_sub_path]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-new-sub-path
[cairo_move_to]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-move-to
[cairo_line_to]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-line-to
[cairo_curve_to]:                          http://cairographics.org/manual/cairo-Paths.html#cairo-curve-to
[cairo_quad_curve_to]:                     http://cairographics.org/manual/cairo-Paths.html#cairo-quad-curve-to
[cairo_arc]:                               http://cairographics.org/manual/cairo-Paths.html#cairo-arc
[cairo_arc_negative]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-arc-negative
[cairo_circle]:                            http://cairographics.org/manual/cairo-Paths.html#cairo-circle
[cairo_ellipse]:                           http://cairographics.org/manual/cairo-Paths.html#cairo-ellipse
[cairo_rel_move_to]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-rel-move-to
[cairo_rel_line_to]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-rel-line-to
[cairo_rel_curve_to]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-rel-curve-to
[cairo_rel_quad_curve_to]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-rel-quad-curve-to
[cairo_rectangle]:                         http://cairographics.org/manual/cairo-Paths.html#cairo-rectangle
[cairo_close_path]:                        http://cairographics.org/manual/cairo-Paths.html#cairo-close-path
[cairo_copy_path]:                         http://cairographics.org/manual/cairo-Paths.html#cairo-copy-path
[cairo_copy_path_flat]:                    http://cairographics.org/manual/cairo-Paths.html#cairo-copy-path-flat
[cairo_append_path]:                       http://cairographics.org/manual/cairo-Paths.html#cairo-append-path
[cairo_path_extents]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-path-extents
[cairo_has_current_point]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-has-current-point
[cairo_get_current_point]:                 http://cairographics.org/manual/cairo-Paths.html#cairo-get-current-point

[cairo_paint]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint
[cairo_paint_with_alpha]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-paint-with-alpha
[cairo_stroke]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke
[cairo_stroke_preserve]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-preserve
[cairo_fill]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill
[cairo_fill_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-preserve
[cairo_in_stroke]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-stroke
[cairo_in_fill]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-fill
[cairo_in_clip]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-in-clip
[cairo_stroke_extents]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-stroke-extents
[cairo_fill_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-fill-extents

[cairo_clip]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip
[cairo_clip_preserve]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-preserve
[cairo_reset_clip]:                        http://cairographics.org/manual/cairo-cairo-t.html#cairo-reset-clip
[cairo_clip_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-clip-extents
[cairo_copy_clip_rectangle_list]:          http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy-clip-rectangle-list

[cairo_pattern_get_type]:                  http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-type
[cairo_pattern_set_matrix]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-matrix
[cairo_pattern_set_extend]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-extend
[cairo_pattern_set_filter]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-set-filter
[cairo_pattern_get_surface]:               http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-surface

[cairo_pattern_create_rgb]:                http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-rgb
[cairo_pattern_create_rgba]:               http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-rgba
[cairo_pattern_get_rgba]:                  http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-rgba

[cairo_pattern_create_linear]:             http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-linear
[cairo_pattern_add_color_stop_rgb]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-add-color-stop-rgb
[cairo_pattern_add_color_stop_rgba]:       http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-add-color-stop-rgba
[cairo_pattern_get_linear_points]:         http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-linear-points
[cairo_pattern_get_color_stop_count]:      http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-count
[cairo_pattern_get_color_stop_rgba]:       http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-color-stop-rgba

[cairo_pattern_create_radial]:             http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-radial
[cairo_pattern_get_radial_circles]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-get-radial-circles

[cairo_pattern_create_for_surface]:        http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-pattern-create-for-surface

[cairo_pattern_create_raster_source]:             http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-create-raster-source
[cairo_raster_source_pattern_set_callback_data]:  http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-callback-data
[cairo_raster_source_pattern_set_acquire]:        http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-acquire
[cairo_raster_source_pattern_set_snapshot]:       http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-snapshot
[cairo_raster_source_pattern_set_copy]:           http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-copy
[cairo_raster_source_pattern_set_finish]:         http://cairographics.org/manual/cairo-Raster-Sources.html#cairo-raster-source-pattern-set-finish

[cairo_pattern_create_mesh]:
