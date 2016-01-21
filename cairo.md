---
tagline: cairo graphics engine
---

## `local cairo = require'cairo'`

A lightweight ffi binding of the [cairo graphics] library.

[cairo graphics]:   http://cairographics.org/

## API

__NOTE:__ In the table below, `foo([val]) /-> val` is a shortcut for saying
that `foo(val)` sets the value of foo and `foo() -> val` gets it.
`t|f` means `true|false`.

<div class="small">
------------------------------------------------------------------- -------------------------------------------------------------------
__pixman surfaces__
`cairo.image_surface(fmt, w, h) -> sr`                              [create a pixman surface][cairo_image_surface_create]
`cairo.image_surface(bmp) -> sr`                                    [create a pixman surface given a][cairo_image_surface_create_for_data] [bitmap]
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
`cr:operator([operator]) /-> operator`                              [get/set operator][cairo_set_operator]
`cr:source([patt | sr, [x, y]]) /-> patt`                           [get/set pattern or surface as source][cairo_set_source]
`cr:rgb(r, g, b)`                                                   [set RGB color as source][cairo_set_source_rgb]
`cr:rgba(r, g, b, a)`                                               [set RGBA color as source][cairo_set_source_rgba]
__groups__
`cr:push_group([content])`                                          [redirect drawing to an intermediate surface][cairo_push_group_with_content]
`cr:pop_group() -> patt`                                            [terminate the redirection and return it as pattern][cairo_pop_group]
`cr:pop_group_to_source()`                                          [terminate the redirection and install it as pattern][cairo_pop_group_to_source]
__transformations__
`cr:translate(x, y)`                                                [translate the user-space origin][cairo_translate]
`cr:scale(sx, sy)`                                                  [scale the user-space][cairo_scale]
`cr:scale_around(cx, cy, sx, sy)`                                   scale the user-space arount a point
`cr:rotate(angle)`                                                  [rotate the user-space][cairo_rotate]
`cr:rotate_around(cx, cy, angle)`                                   rotate the user-space around a point
`cr:transform(mt)`                                                  [transform the user-space][cairo_transform]
`cr:safe_transform(mt)`                                             transform the user-space if the matrix is invertible
`cr:matrix([mt]) /-> mt`                                            [get/set the CTM][cairo_set_matrix]
`cr:identity_matrix()`                                              [reset the CTM][cairo_identity_matrix]
`cr:skew(ax, ay)`                                                   skew the user-space
__paths__
`cr:new_path()`                                                     [create path][cairo_new_path]
`cr:new_sub_path()`                                                 [create sub-path][cairo_new_sub_path]
`cr:move_to(x, y)`                                                  [move the current point][cairo_move_to]
`cr:has_current_point() -> t|f`                                     [check if there's a current point][cairo_has_current_point]
`cr:current_point() -> x, y`                                        [return the current point][cairo_get_current_point]
`cr:line_to(x, y)`                                                  [add a line to the current path][cairo_line_to]
`cr:curve_to(x1, y1, x2, y2, x3, y3)`                               [add a cubic bezier to the current path][cairo_curve_to]
`cr:quad_curve_to(x1, y1, x2, y2)`                                  [add a quad bezier to the current path][cairo_quad_curve_to]
`cr:arc(cx, cy, radius, a1, a2)`                                    [add an arc to the current path][cairo_arc]
`cr:arc_negative(cx, cy, r, a1, a2)`                                [add a negative arc to the current path][cairo_arc_negative]
`cr:circle(cx, cy, r)`                                              [add a circle to the current path][cairo_circle]
`cr:ellipse(cx, cy, rx, ry, rotation)`                              [add an ellipse to the current path][cairo_ellipse]
`cr:rel_move_to(x, y)`                                              [move the current point][cairo_rel_move_to]
`cr:rel_line_to(x, y)`                                              [add a line to the current path][cairo_rel_line_to]
`cr:rel_curve_to(x1, y1, x2, y2, x3, y3)`                           [add a cubic bezier to the current path][cairo_rel_curve_to]
`cr:rel_quad_curve_to(x1, y1, x2, y2)`                              [add a quad bezier to the current path][cairo_rel_quad_curve_to]
`cr:rectangle(x, y, w, h)`                                          [add a rectangle to the current path][cairo_rectangle]
`cr:close_path()`                                                   [close current path][cairo_close_path]
`cr:path_extents() -> x1, y1, x2, y2`                               [bouding box of current path][cairo_path_extents]
`cr:copy_path() -> path`                                            [copy current path to a path object][cairo_copy_path]
`cr:copy_path_flat() -> path`                                       [copy current path flattened][cairo_copy_path_flat]
`cr:append_path(path)`                                              [append a path to current path][cairo_append_path]
__filling and stroking__
`cr:paint()`                                                        [paint the source over surface][cairo_paint]
`cr:paint_with_alpha(alpha)`                                        [paint the source with transparency][cairo_paint_with_alpha]
`cr:mask(patt | sr[, x, y])`                                        [draw using pattern's (or surface's) alpha as a mask][cairo_mask]
`cr:stroke()`                                                       [stroke and discard the current path][cairo_stroke]
`cr:stroke_preserve()`                                              [stroke and keep the path][cairo_stroke_preserve]
`cr:fill()`                                                         [fill and discard the current path][cairo_fill]
`cr:fill_preserve()`                                                [fill and keep the path][cairo_fill_preserve]
`cr:in_stroke(x, y) -> t|f`                                         [hit-test the stroke area][cairo_in_stroke]
`cr:in_fill(x, y) -> t|f`                                           [hit-test the fill area][cairo_in_fill]
`cr:in_clip(x, y) -> t|f`                                           [hit-test the clip area][cairo_in_clip]
`cr:stroke_extents() -> x1, y1, x2, y2`                             [get the stroke extents][cairo_stroke_extents]
`cr:fill_extents() -> x1, y1, x2, y2`                               [get the fill extents][cairo_fill_extents]
__clipping__
`cr:reset_clip()`                                                   [remove all clipping][cairo_reset_clip]
`cr:clip()`                                                         [clip and discard the current path][cairo_clip]
`cr:clip_preserve()`                                                [clip and keep the current path][cairo_clip_preserve]
`cr:clip_extents() -> x1, y1, x2, y2`                               [get the clip extents][cairo_clip_extents]
`cr:copy_clip_rectangles() -> rlist`                                [get the clipping rectangles][cairo_copy_clip_rectangle_list]
__patterns__
`patt:type() -> type`                                               [get the pattern type][cairo_get_type]
`patt:matrix([mt]) /-> mt`                                          [get/set the matrix][cairo_set_matrix]
`patt:extend([extend]) /-> extend`                                  [get/set the extend][cairo_set_extend]
`patt:filter([filter]) /-> filter`                                  [get/set the filter][cairo_set_filter]
`patt:surface() -> sr | nil`                                        [get the pattern's surface][cairo_get_surface]
__color-filled patterns__
`cairo.rgb_pattern(r, g, b) -> patt`                                [create a matte color pattern][cairo_pattern_create_rgb]
`cairo.rgba_pattern(r, g, b, a) -> patt`                            [create a transparent color pattern][cairo_pattern_create_rgba]
`patt:rgba() -> r, g, b, a`                                         [get RGBA color][cairo_get_rgba]
__linear gradient patterns__
`cairo.linear_pattern(x0, y0, x1, y1) -> patt`                      [create a linear gradient][cairo_pattern_create_linear]
`patt:add_color_stop_rgb(offset, r, g, b)`                          [add a RGB color stop][cairo_add_color_stop_rgb]
`patt:add_color_stop_rgba(offset, r, g, b, a)`                      [add a RGBA color stop][cairo_add_color_stop_rgba]
`patt:linear_points() -> x0, y0, x1, y1`                            [get points of linear gradient][cairo_get_linear_points]
`patt:color_stop_count() -> n`                                      [get the number of color stops][cairo_get_color_stop_count]
`patt:color_stop_rgba(i) -> offset, r, g, b, a`                     [get a color stop][cairo_get_color_stop_rgba]
__radial gradient patterns__
`cairo.radial_pattern(cx0, cy0, r0, cx1, cy1, r1) -> patt`          [create a radial gradient][cairo_pattern_create_radial]
`patt:radial_circles() -> cx0, cy0, r0, cx1, cy1, r1`               [get circles of radial gradient][cairo_get_radial_circles]
__raster patterns__
`cairo.raster_source(data, content, w, h) -> patt`                  [create a pattern from a raster image][cairo_pattern_create_raster_source]
`sr:pattern() -> patt`                                              [create a pattern from a surface][cairo_pattern_create_for_surface]
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
`mat:init()`                                                        [ref][cairo_init]
`mat:init_identity()`                                               [ref][cairo_init_identity]
`mat:init_translate()`                                              [ref][cairo_init_translate]
`mat:init_scale()`                                                  [ref][cairo_init_scale]
`mat:init_rotate()`                                                 [ref][cairo_init_rotate]
`mat:translate(x, y)`                                               [ref][cairo_translate]
`mat:scale(sx, sy)`                                                 [ref][cairo_scale]
`mat:rotate(angle)`                                                 [ref][cairo_rotate]
`mat:rotate_around(cx, cy, angle)`                                  [ref][cairo_rotate_around]
`mat:scale_around(cx, cy, sx, sy)`                                  [ref][cairo_scale_around]
`mat:invert()`                                                      [ref][cairo_invert]
`mat:multiply()`                                                    [ref][cairo_multiply]
`mat:transform_point(x, y) -> x, y`                                 [ref][cairo_transform_point]
`mat:transform_distance(x, y) -> x, y`                              [ref][cairo_transform_distance]
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
`cairo.version_string() -> s`                                       [get lib version as X.Y.Z][cairo_version_string]
------------------------------------------------------------------- -------------------------------------------------------------------
</div>

> (*) for ref-counted objects only: `cr`, `sr`, `dev`, `patt`, `sfont`, `font` and `rgn`.



[cairo_version]:                           http://cairographics.org/manual/cairo-Version-Information.html#cairo-version
[cairo_version_string]:                    http://cairographics.org/manual/cairo-Version-Information.html#cairo-version-string

[cairo_format_stride_for_width]:           ??

[cairo_glyph_allocate]:                    http://cairographics.org/manual/cairo-text.html#cairo-glyph-allocate
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
[cairo_text_cluster_allocate]:             http://cairographics.org/manual/cairo-text.html#cairo-text-cluster-allocate
[cairo_text_cluster_free]:                 http://cairographics.org/manual/cairo-text.html#cairo-text-cluster-free

[cairo_font_options_create]:               http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-create
[cairo_font_options_copy]:                 http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-copy
[cairo_font_options_free]:                 http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-free
[cairo_font_options_status]:               http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-status
[cairo_font_options_status_message]:        http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-status-string
[cairo_font_options_merge]:                http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-merge
[cairo_font_options_equal]:                http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-equal
[cairo_font_options_hash]:                 http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-hash
[cairo_font_options_set_antialias]:        http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-antialias
[cairo_font_options_get_antialias]:        http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-antialias
[cairo_font_options_set_subpixel_order]:   http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-subpixel-order
[cairo_font_options_get_subpixel_order]:   http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-subpixel-order
[cairo_font_options_set_hint_style]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-hint-style
[cairo_font_options_get_hint_style]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-hint-style
[cairo_font_options_set_hint_metrics]:     http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-hint-metrics
[cairo_font_options_get_hint_metrics]:     http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-hint-metrics
[cairo_font_options_set_lcd_filter]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-lcd-filter
[cairo_font_options_get_lcd_filter]:       http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-lcd-filter
[cairo_font_options_set_round_glyph_positions]: http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-set-round-glyph-positions
[cairo_font_options_get_round_glyph_positions]: http://cairographics.org/manual/cairo-cairo-font-options-t.html#cairo-font-options-get-round-glyph-positions

[cairo_create]:                            http://cairographics.org/manual/cairo-t.html#cairo-create
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
[cairo_translate]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-translate
[cairo_scale]:                             http://cairographics.org/manual/cairo-Transformations.html#cairo-scale
[cairo_rotate]:                            http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate
[cairo_rotate_around]:                     http://cairographics.org/manual/cairo-Transformations.html#cairo-rotate-around
[cairo_scale_around]:                      http://cairographics.org/manual/cairo-Transformations.html#cairo-scale-around
[cairo_transform]:                         http://cairographics.org/manual/cairo-Transformations.html#cairo-transform
[cairo_safe_transform]:                    http://cairographics.org/manual/cairo-Transformations.html#cairo-safe-transform
[cairo_set_matrix]:                        http://cairographics.org/manual/cairo-Transformations.html#cairo-set-matrix
[cairo_identity_matrix]:                   http://cairographics.org/manual/cairo-Transformations.html#cairo-identity-matrix
[cairo_skew]:                              http://cairographics.org/manual/cairo-Transformations.html#cairo-skew
[cairo_user_to_device]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-to-device
[cairo_user_to_device_distance]:           http://cairographics.org/manual/cairo-cairo-t.html#cairo-user-to-device-distance
[cairo_device_to_user]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-device-to-user
[cairo_device_to_user_distance]:           http://cairographics.org/manual/cairo-cairo-t.html#cairo-device-to-user-distance

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
[cairo_path_destroy]:                      http://cairographics.org/manual/cairo-Paths.html#cairo-path-destroy

[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_to_string]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-to-string
[cairo_reference]:                         http://cairographics.org/manual/cairo-cairo-t.html#cairo-reference
[cairo_get_reference_count]:               http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-reference-count
[cairo_destroy]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-destroy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free

[cairo_image_surface_create]:                    http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create
[cairo_image_surface_create_for_data]:           http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-create-for-data
[cairo_image_surface_get_data]:                  http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-data
[cairo_image_surface_get_format]:                http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-format
[cairo_image_surface_get_width]:                 http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-width
[cairo_image_surface_get_height]:                http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-height
[cairo_image_surface_get_stride]:                http://cairographics.org/manual/cairo-Image-Surfaces.html#cairo-image-surface-get-stride

[cairo_image_surface_create_from_png]:           http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png
[cairo_image_surface_create_from_png_stream]:    http://cairographics.org/manual/cairo-PNG-Support.html#cairo-image-surface-create-from-png-stream
[cairo_surface_write_to_png]:                    http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png
[cairo_surface_write_to_png_stream]:             http://cairographics.org/manual/cairo-PNG-Support.html#cairo-surface-write-to-png-stream

[cairo_recording_surface_create]:          http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-create
[cairo_recording_surface_ink_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-ink-extents
[cairo_recording_surface_get_extents]:     http://cairographics.org/manual/cairo-Recording-Surfaces.html#cairo-recording-surface-get-extents

[cairo_surface_create_similar]:            http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar
[cairo_surface_create_similar_image]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-similar-image
[cairo_surface_create_for_rectangle]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-for-rectangle
[cairo_surface_map_to_image]:              http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-map-to-image
[cairo_surface_unmap_image]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-unmap-image
[cairo_surface_create_observer]:           http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-create-observer
[cairo_surface_finish]:                    http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-finish
[cairo_surface_get_device]:                http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-device
[cairo_surface_status]:                    http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-status
[cairo_surface_status_message]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-status-string
[cairo_surface_get_type]:                  http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-type
[cairo_surface_get_content]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-content
[cairo_surface_get_mime_data]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-mime-data
[cairo_surface_set_mime_data]:             http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-mime-data
[cairo_surface_supports_mime_type]:        http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-supports-mime-type
[cairo_surface_get_font_options]:          http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-font-options
[cairo_surface_flush]:                     http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-flush
[cairo_surface_mark_dirty]:                http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-mark-dirty
[cairo_surface_mark_dirty_rectangle]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-mark-dirty-rectangle
[cairo_surface_set_device_offset]:         http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-device-offset
[cairo_surface_get_device_offset]:         http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-device-offset
[cairo_surface_set_fallback_resolution]:   http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-set-fallback-resolution
[cairo_surface_get_fallback_resolution]:   http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-fallback-resolution
[cairo_surface_copy_page]:                 http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-copy-page
[cairo_surface_show_page]:                 http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-show-page
[cairo_surface_has_show_text_glyphs]:      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-has-show-text-glyphs

[cairo_surface_create_pattern]:            http://cairographics.org/manual/cairo-cairo-pattern-t.html#cairo-surface-create-pattern

[cairo_surface_apply_alpha]:               http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-apply-alpha
[cairo_surface_reference]:                 http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-reference
[cairo_surface_get_reference_count]:       http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-get-reference-count
[cairo_surface_destroy]:                   http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-destroy
[cairo_surface_free]:                      http://cairographics.org/manual/cairo-cairo-surface-t.html#cairo-surface-free

[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_acquire]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-acquire
[cairo_release]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-release
[cairo_flush]:                             http://cairographics.org/manual/cairo-cairo-t.html#cairo-flush
[cairo_finish]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-finish
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
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
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
[cairo_extents]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-extents
[cairo_text_extents]:                      http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-extents
[cairo_glyph_extents]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-glyph-extents
[cairo_text_to_glyphs]:                    http://cairographics.org/manual/cairo-cairo-t.html#cairo-text-to-glyphs
[cairo_get_font_face]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-face
[cairo_get_font_matrix]:                   http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-matrix
[cairo_get_ctm]:                           http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-ctm
[cairo_get_scale_matrix]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-scale-matrix
[cairo_get_font_options]:                  http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-font-options
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
[cairo_get_type]:                          http://cairographics.org/manual/cairo-cairo-t.html#cairo-get-type
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
[cairo_copy]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-copy
[cairo_free]:                              http://cairographics.org/manual/cairo-cairo-t.html#cairo-free
[cairo_status]:                            http://cairographics.org/manual/cairo-cairo-t.html#cairo-status
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
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
[cairo_status_message]:                     http://cairographics.org/manual/cairo-cairo-t.html#cairo-status-string
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


## Luaization

  * cairo types have associated methods, so you can use `context:paint()`
  instead of `cairo.paint(context)`.
  * pointers to objects for which cairo holds no references are bound to
  Lua's garbage collector to prevent leaks.
  * ref-counted objects have a free() method that checks ref. count and a
  destroy() method that doesn't.
  * functions that work with `char*` are made to accept/return Lua strings.
  * enums can be passed in as strings, in lowercase and without prefix.
  * output buffers can be allocated internally or passed in as arguments.
  * the included binary is built with support for in-memory surfaces,
  recording surfaces, ps surfaces, pdf surfaces, svg surfaces, win32 surfaces,
  win32 fonts and freetype fonts.

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
</div>

Also, `cairo.image_surface(bmp) -> surface`
creates a cairo image surface from a [bitmap] object if it's in one
of the supported formats: 'bgra8', 'bgrx8', 'g8', 'g1', 'rgb565'.
