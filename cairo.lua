
-- cairo graphics library ffi binding.
-- Written by Cosmin Apreutesei. Public Domain.

-- Supports garbage collection, metatype methods, accepting and returning
-- strings, returning multiple values instead of passing output buffers,
-- and API additions for completeness (drawing quad curves, getting and
-- setting pixel values, etc.). Note that methods from specific backends and
-- extensions are not added and cannot be added after loading this module
-- due to limitations of ffi.metatype(). An exception is made for the pixman
-- backend because it's a required dependency on all platforms.
-- Still looking for a nice way to solve this.

local ffi = require'ffi'
require'cairo_h'
local C = ffi.load'cairo'
local M = setmetatable({C = C}, {__index = C})

local function sym(name) return C[name] end
local function if_exists(name) --return M[name] only if C[name] exists in the C library
    return pcall(sym, name) and M[name] or nil
end

-- garbage collector / ref'counting integration
-- NOTE: free() and destroy() do not return a value to enable the idiom
-- self.obj = self.obj:free().

local function free_ref_counted(o)
	local n = o:get_reference_count() - 1
	o:destroy()
	if n ~= 0  then
		error(string.format('refcount of %s is %d, should be 0', tostring(o), n))
	end
end

function M.cairo_destroy(cr)
	ffi.gc(cr, nil)
	C.cairo_destroy(cr)
end

function M.cairo_surface_destroy(surface)
	ffi.gc(surface, nil)
	C.cairo_surface_destroy(surface)
end

function M.cairo_device_destroy(device)
	ffi.gc(device, nil)
	C.cairo_device_destroy(device)
end

function M.cairo_pattern_destroy(pattern)
	ffi.gc(pattern, nil)
	C.cairo_pattern_destroy(pattern)
end

function M.cairo_scaled_font_destroy(font)
	ffi.gc(font, nil)
	C.cairo_scaled_font_destroy(font)
end

function M.cairo_font_face_destroy(ff)
	ffi.gc(ff, nil)
	C.cairo_font_face_destroy(ff)
end

function M.cairo_font_options_destroy(ff)
	ffi.gc(ff, nil)
	C.cairo_font_options_destroy(ff)
end

function M.cairo_region_destroy(region)
	ffi.gc(region, nil)
	C.cairo_region_destroy(region)
end

function M.cairo_path_destroy(path)
	ffi.gc(path, nil)
	C.cairo_path_destroy(path)
end

function M.cairo_rectangle_list_destroy(rl)
	ffi.gc(rl, nil)
	C.cairo_rectangle_list_destroy(rl)
end

function M.cairo_glyph_free(c)
	ffi.gc(c, nil)
	C.cairo_glyph_free(c)
end

function M.cairo_text_cluster_free(c)
	ffi.gc(c, nil)
	C.cairo_text_cluster_free(c)
end

function M.cairo_create(...)
	return ffi.gc(C.cairo_create(...), M.cairo_destroy)
end

function M.cairo_reference(...)
	return ffi.gc(C.cairo_reference(...), M.cairo_destroy)
end

function M.cairo_pop_group(...)
	return ffi.gc(C.cairo_pop_group(...), M.cairo_pattern_destroy)
end

local function check_surface(surface)
	assert(surface:status() == C.CAIRO_STATUS_SUCCESS, surface:status_string())
	return surface
end

function M.cairo_surface_create_similar(...)
	return ffi.gc(check_surface(C.cairo_surface_create_similar(...)), M.cairo_surface_destroy)
end

function M.cairo_surface_create_similar_image(...)
	return ffi.gc(check_surface(C.cairo_surface_create_similar_image(...)), M.cairo_surface_destroy)
end

function M.cairo_surface_create_for_rectangle(...)
	return ffi.gc(check_surface(C.cairo_surface_create_for_rectangle(...)), M.cairo_surface_destroy)
end

function M.cairo_surface_create_for_data(...)
	return ffi.gc(check_surface(C.cairo_surface_create_for_data(...)), M.cairo_surface_destroy)
end

function M.cairo_surface_create_observer(...)
	return ffi.gc(check_surface(C.cairo_surface_create_observer(...)), M.cairo_surface_destroy)
end

function M.cairo_surface_reference(...)
	return ffi.gc(C.cairo_surface_reference(...), M.cairo_surface_destroy)
end

function M.cairo_image_surface_create(...)
	return ffi.gc(check_surface(C.cairo_image_surface_create(...)), M.cairo_surface_destroy)
end

function M.cairo_image_surface_create_for_data(...)
	return ffi.gc(check_surface(C.cairo_image_surface_create_for_data(...)), M.cairo_surface_destroy)
end

function M.cairo_image_surface_create_from_png(...)
	return ffi.gc(check_surface(C.cairo_image_surface_create_from_png(...)), M.cairo_surface_destroy)
end

function M.cairo_image_surface_create_from_png_stream(...)
	return ffi.gc(check_surface(C.cairo_image_surface_create_from_png_stream(...)), M.cairo_surface_destroy)
end

local formats = {
	bgra8  = C.CAIRO_FORMAT_ARGB32,
	bgrx8  = C.CAIRO_FORMAT_RGB24,
	g8     = C.CAIRO_FORMAT_A8,
	g1     = C.CAIRO_FORMAT_A1,
	rgb565 = C.CAIRO_FORMAT_RGB16_565,
}
function M.cairo_image_surface_create_from_bitmap(bmp)
	local format = assert(formats[bmp.format], 'unsupported format')
	return M.cairo_image_surface_create_for_data(bmp.data, format, bmp.w, bmp.h, bmp.stride)
end

function M.cairo_recording_surface_create(...)
	return ffi.gc(check_surface(C.cairo_recording_surface_create(...)), M.cairo_surface_destroy)
end

function M.cairo_device_reference(...)
	return ffi.gc(C.cairo_device_reference(...), M.cairo_device_destroy)
end

function M.cairo_pattern_create_raster_source(...)
	return ffi.gc(C.cairo_pattern_create_raster_source(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_rgb(...)
	return ffi.gc(C.cairo_pattern_create_rgb(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_rgba(...)
	return ffi.gc(C.cairo_pattern_create_rgba(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_for_surface(...)
	return ffi.gc(C.cairo_pattern_create_for_surface(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_linear(...)
	return ffi.gc(C.cairo_pattern_create_linear(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_radial(...)
	return ffi.gc(C.cairo_pattern_create_radial(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_create_mesh(...)
	return ffi.gc(C.cairo_pattern_create_mesh(...), M.cairo_pattern_destroy)
end

function M.cairo_pattern_reference(...)
	return ffi.gc(C.cairo_pattern_reference(...), M.cairo_pattern_destroy)
end

function M.cairo_scaled_font_create(...)
	return ffi.gc(C.cairo_scaled_font_create(...), M.cairo_scaled_font_destroy)
end

function M.cairo_scaled_font_reference(...)
	return ffi.gc(C.cairo_scaled_font_reference(...), M.cairo_scaled_font_destroy)
end

function M.cairo_toy_font_face_create(...)
	return ffi.gc(C.cairo_toy_font_face_create(...), M.cairo_font_face_destroy)
end

function M.cairo_user_font_face_create(...)
	return ffi.gc(C.cairo_user_font_face_create(...), M.cairo_font_face_destroy)
end

function M.cairo_font_face_reference(...)
	return ffi.gc(C.cairo_font_face_reference(...), M.cairo_font_face_destroy)
end

function M.cairo_font_options_create(...)
	return ffi.gc(C.cairo_font_options_create(...), M.cairo_font_options_destroy)
end

function M.cairo_region_create(...)
	return ffi.gc(C.cairo_region_create(...), M.cairo_region_destroy)
end

function M.cairo_region_create_rectangle(...)
	return ffi.gc(C.cairo_region_create_rectangle(...), M.cairo_region_destroy)
end

function M.cairo_region_create_rectangles(...)
	return ffi.gc(C.cairo_region_create_rectangles(...), M.cairo_region_destroy)
end

function M.cairo_region_copy(...)
	return ffi.gc(C.cairo_region_copy(...), M.cairo_region_destroy)
end

function M.cairo_region_reference(...)
	return ffi.gc(C.cairo_region_reference(...), M.cairo_region_destroy)
end

function M.cairo_copy_path(...)
	return ffi.gc(C.cairo_copy_path(...), M.cairo_path_destroy)
end

function M.cairo_copy_path_flat(...)
	return ffi.gc(C.cairo_copy_path_flat(...), M.cairo_path_destroy)
end

function M.cairo_copy_clip_rectangle_list(...)
	return ffi.gc(C.cairo_copy_clip_rectangle_list(...), M.cairo_rectangle_list_destroy)
end

function M.cairo_glyph_allocate(...)
	return ffi.gc(C.cairo_glyph_allocate(...), M.cairo_glyph_free)
end

function M.cairo_text_cluster_allocate(...)
	return ffi.gc(C.cairo_text_cluster_allocate(...), M.cairo_text_cluster_free)
end

-- char* return -> string return

function M.cairo_version_string()
	return ffi.string(C.cairo_version_string())
end

function M.cairo_status_to_string(status)
	return ffi.string(C.cairo_status_to_string(status))
end

local function status_string(self)
	return M.cairo_status_to_string(self:status())
end

-- int return -> bool return

local function returns_bool(f)
	return f and function(...)
		return f(...) ~= 0
	end
end

M.cairo_in_stroke = returns_bool(M.cairo_in_stroke)
M.cairo_in_fill = returns_bool(M.cairo_in_fill)
M.cairo_in_clip = returns_bool(M.cairo_in_clip)
M.cairo_has_current_point = returns_bool(M.cairo_has_current_point)
M.cairo_surface_has_show_text_glyphs = returns_bool(M.cairo_surface_has_show_text_glyphs)
M.cairo_font_options_equal = returns_bool(M.cairo_font_options_equal)
M.cairo_region_equal = returns_bool(M.cairo_region_equal)
M.cairo_region_is_empty = returns_bool(M.cairo_region_is_empty)
M.cairo_region_contains_point = returns_bool(M.cairo_region_contains_point)

-- return multiple values instead of passing output buffers

function M.cairo_get_matrix(cr, mt)
	mt = mt or ffi.new'cairo_matrix_t'
	C.cairo_get_matrix(cr, mt)
	return mt
end

function M.cairo_pattern_get_matrix(pat, mt)
	mt = mt or ffi.new'cairo_matrix_t'
	C.cairo_pattern_get_matrix(pat, mt)
	return mt
end

local dx = ffi.new'double[1]'
local dy = ffi.new'double[1]'
function M.cairo_get_current_point(cr)
	C.cairo_get_current_point(cr, dx, dy)
	return dx[0], dy[0]
end

local dx1 = ffi.new'double[1]'
local dy1 = ffi.new'double[1]'
local dx2 = ffi.new'double[1]'
local dy2 = ffi.new'double[1]'
local function extents_function(f)
	return function(cr)
		f(cr, dx1, dy1, dx2, dy2)
		return dx1[0], dy1[0], dx2[0], dy2[0]
	end
end

M.cairo_clip_extents = extents_function(C.cairo_clip_extents)
M.cairo_fill_extents = extents_function(C.cairo_fill_extents)
M.cairo_stroke_extents = extents_function(C.cairo_stroke_extents)
M.cairo_path_extents = extents_function(C.cairo_path_extents)

local surface = ffi.new'cairo_surface_t*[1]'
function M.cairo_pattern_get_surface(self, surface)
	C.cairo_pattern_get_surface(self, surface)
	return surface[0]
end

local dx = ffi.new'double[1]'
local dy = ffi.new'double[1]'
local function point_transform_function(f)
	return function(cr, x, y)
		dx[0], dy[0] = x, y
		f(cr, dx, dy)
		return dx[0], dy[0]
	end
end

M.cairo_device_to_user = point_transform_function(C.cairo_device_to_user)
M.cairo_user_to_device = point_transform_function(C.cairo_user_to_device)
M.cairo_user_to_device_distance = point_transform_function(C.cairo_user_to_device_distance)
M.cairo_device_to_user_distance = point_transform_function(C.cairo_device_to_user_distance)

function M.cairo_text_extents(cr, s, extents)
	extents = extents or ffi.new'cairo_text_extents_t'
	C.cairo_text_extents(cr, s, extents)
	return extents
end

function M.cairo_glyph_extents(cr, glyphs, num_glyphs, extents)
	extents = extents or ffi.new'cairo_text_extents_t'
	C.cairo_glyph_extents(cr, glyphs, num_glyphs, extents)
	return extents
end

function M.cairo_font_extents(cr, extents)
	extents = extents or ffi.new'cairo_font_extents_t'
	C.cairo_font_extents(cr, extents)
	return extents
end

-- quad beziers addition

function M.cairo_quad_curve_to(cr, x1, y1, x2, y2)
	local x0, y0 = cr:get_current_point()
	cr:curve_to((x0 + 2 * x1) / 3,
					(y0 + 2 * y1) / 3,
					(x2 + 2 * x1) / 3,
					(y2 + 2 * y1) / 3,
					x2, y2)
end

function M.cairo_rel_quad_curve_to(cr, x1, y1, x2, y2)
	local x0, y0 = cr:get_current_point()
	M.cairo_quad_curve_to(cr, x0+x1, y0+y1, x0+x2, y0+y2)
end

-- arcs addition

local pi = math.pi
function M.cairo_circle(cr, cx, cy, r)
	cr:new_sub_path()
	cr:arc(cx, cy, r, 0, 2 * pi)
	cr:close_path()
end

function M.cairo_ellipse(cr, cx, cy, rx, ry, rotation)
	local mt = cr:get_matrix()
	cr:translate(cx, cy)
	if rotation then cr:rotate(rotation) end
	cr:scale(1, ry/rx)
	cr:circle(0, 0, rx)
	cr:set_matrix(mt)
end

-- matrix additions

function M.cairo_matrix_transform(dmt, mt)
	dmt:multiply(mt, dmt)
	return dmt
end

function M.cairo_matrix_invertible(mt, tmt)
	tmt = tmt or ffi.new'cairo_matrix_t'
	ffi.copy(tmt, mt, ffi.sizeof(mt))
	return tmt:invert() == 0
end

function M.cairo_matrix_safe_transform(dmt, mt)
	if mt:invertible() then dmt:transform(mt) end
end

function M.cairo_matrix_skew(mt, ax, ay)
	local sm = ffi.new'cairo_matrix_t'
	sm:init_identity()
	sm.xy = math.tan(ax)
	sm.yx = math.tan(ay)
	mt:transform(sm)
end

function M.cairo_matrix_rotate_around(mt, cx, cy, angle)
	mt:translate(cx, cy)
	mt:rotate(angle)
	mt:translate(-cx, -cy)
end

function M.cairo_matrix_scale_around(mt, cx, cy, ...)
	mt:translate(cx, cy)
	mt:scale(...)
	mt:translate(-cx, -cy)
end

function M.cairo_matrix_copy(mt)
	local dmt = ffi.new'cairo_matrix_t'
	ffi.copy(dmt, mt, ffi.sizeof(mt))
	return dmt
end

function M.cairo_matrix_init_matrix(dmt, mt)
	ffi.copy(dmt, mt, ffi.sizeof(mt))
end

-- context additions

function M.cairo_safe_transform(cr, mt)
	if mt:invertible() then cr:transform(mt) end
end

function M.cairo_rotate_around(cr, cx, cy, angle)
	M.cairo_translate(cr, cx, cy)
	M.cairo_rotate(cr, angle)
	M.cairo_translate(cr, -cx, -cy)
end

function M.cairo_scale_around(cr, cx, cy, ...)
	M.cairo_translate(cr, cx, cy)
	M.cairo_scale(cr, ...)
	M.cairo_translate(cr, -cx, -cy)
end

function M.cairo_skew(cr, ax, ay)
	local sm = ffi.new'cairo_matrix_t'
	sm:init_identity()
	sm.xy = math.tan(ax)
	sm.yx = math.tan(ay)
	cr:transform(sm)
end

-- surface additions

function M.cairo_surface_apply_alpha(surface, alpha)
	if alpha >= 1 then return end
	local cr = surface:create_context()
	cr:set_source_rgba(0,0,0,alpha)
	cr:set_operator(cairo.CAIRO_OPERATOR_DEST_IN) --alphas are multiplied, dest. color is preserved
	cr:paint()
	cr:free()
end

local image_surface_bpp = {
    [C.CAIRO_FORMAT_ARGB32] = 32,
    [C.CAIRO_FORMAT_RGB24] = 32,
    [C.CAIRO_FORMAT_A8] = 8,
    [C.CAIRO_FORMAT_A1] = 1,
    [C.CAIRO_FORMAT_RGB16_565] = 16,
    [C.CAIRO_FORMAT_RGB30] = 30,
}

function M.cairo_image_surface_get_bpp(surface)
	return image_surface_bpp[tonumber(surface:get_image_format())]
end

--return a getpixel function for a surface that returns pixel components based on surface image format:
--for ARGB32: getpixel(x, y) -> r, g, b, a
--for RGB24:  getpixel(x, y) -> r, g, b
--for A8:     getpixel(x, y) -> a
--for A1:     getpixel(x, y) -> a
--for RGB16:  getpixel(x, y) -> r, g, b
--for RGB30:  getpixel(x, y) -> r, g, b
function M.cairo_image_surface_get_pixel_function(surface)
	local data   = surface:get_image_data()
	local format = surface:get_image_format()
	local w      = surface:get_image_width()
	local h      = surface:get_image_height()
	local stride = surface:get_image_stride()
	local getpixel
	data = ffi.cast('uint8_t*', data)
	if format == C.CAIRO_FORMAT_ARGB32 then
		if ffi.abi'le' then
			error'NYI'
		else
			error'NYI'
		end
	elseif format == C.CAIRO_FORMAT_RGB24 then
		function getpixel(x, y)
			assert(x < w and y < h and x >= 0 and y >= 0, 'out of range')
			return
				data[y * stride + x * 4 + 2],
				data[y * stride + x * 4 + 1],
				data[y * stride + x * 4 + 0]
		end
	elseif format == C.CAIRO_FORMAT_A8 then
		function getpixel(x, y)
			assert(x < w and y < h and x >= 0 and y >= 0, 'out of range')
			return data[y * stride + x]
		end
	elseif format == C.CAIRO_FORMAT_A1 then
		if ffi.abi'le' then
			error'NYI'
		else
			error'NYI'
		end
	elseif format == C.CAIRO_FORMAT_RGB16_565 then
		error'NYI'
	elseif format == C.CAIRO_FORMAT_RGB30 then
		error'NYI'
	else
		error'unsupported image format'
	end
	return getpixel
end

--return a setpixel function analog to getpixel above.
function M.cairo_image_surface_set_pixel_function(surface)
	local data   = surface:get_image_data()
	local format = surface:get_image_format()
	local w      = surface:get_image_width()
	local h      = surface:get_image_height()
	local stride = surface:get_image_stride()
	data = ffi.cast('uint8_t*', data)
	local setpixel
	if format == C.CAIRO_FORMAT_ARGB32 then
		if ffi.abi'le' then
			error'NYI'
		else
			error'NYI'
		end
	elseif format == C.CAIRO_FORMAT_RGB24 then
		function setpixel(x, y, r, g, b)
			assert(x < w and y < h and x >= 0 and y >= 0, 'out of range')
			data[y * stride + x * 4 + 2] = r
			data[y * stride + x * 4 + 1] = g
			data[y * stride + x * 4 + 0] = b
		end
	elseif format == C.CAIRO_FORMAT_A8 then
		function setpixel(x, y, a)
			assert(x < w and y < h and x >= 0 and y >= 0, 'out of range')
			data[y * stride + x] = a
		end
	elseif format == C.CAIRO_FORMAT_A1 then
		if ffi.abi'le' then
			error'NYI'
		else
			error'NYI'
		end
	elseif format == C.CAIRO_FORMAT_RGB16_565 then
		error'NYI'
	elseif format == C.CAIRO_FORMAT_RGB30 then
		error'NYI'
	else
		error'unsupported image format'
	end
	return setpixel
end

-- luaization overrides

local function X(prefix, value)
	return type(value) == 'string' and C[prefix..value:upper()] or value
end

function M.cairo_push_group_with_content(cr, content)
	C.cairo_push_group_with_content(cr, X('CAIRO_CONTENT_', content))
end

function M.cairo_set_operator(cr, operator)
	C.cairo_set_operator(cr, X('CAIRO_OPERATOR_', operator)
end

function M.cairo_set_antialias(cr, antialias)
	C.cairo_set_antialias(cr, X('CAIRO_ANTIALIAS_', antialias))
end

function M.cairo_set_fill_rule(cr, fill_rule)
	C.cairo_set_fill_rule(cr, X('CAIRO_FILL_RULE_', fill_rule))
end

function M.cairo_set_line_cap(cr, line_cap)
	C.cairo_set_line_cap(cr, X('CAIRO_LINE_CAP_', line_cap))
end

function M.cairo_set_line_join(cr, line_join)
	C.cairo_set_line_join(cr, X('CAIRO_LINE_JOIN_', line_join))
end

function M.cairo_set_dash(cr, dashes, num_dashes, offset)
	if type(dashes) == 'table' then
		offset = num_dashes
		dashes = ffi.new('double[?]', #dashes, dashes)
	end
	C.cairo_set_dash(cr, dashes, num_dashes, offset)
end

-- metamethods

ffi.metatype('cairo_t', {__index = {
	reference = M.cairo_reference,
	destroy = M.cairo_destroy,
	free = free_ref_counted,
	get_reference_count = M.cairo_get_reference_count,
	get_user_data = M.cairo_get_user_data,
	set_user_data = M.cairo_set_user_data,
	save = M.cairo_save,
	restore = M.cairo_restore,
	push_group = M.cairo_push_group,
	push_group_with_content = M.cairo_push_group_with_content,
	pop_group = M.cairo_pop_group,
	pop_group_to_source = M.cairo_pop_group_to_source,
	set_operator = M.cairo_set_operator,
	set_source = M.cairo_set_source,
	set_source_rgb = M.cairo_set_source_rgb,
	set_source_rgba = M.cairo_set_source_rgba,
	set_source_surface = M.cairo_set_source_surface,
	set_tolerance = M.cairo_set_tolerance,
	set_antialias = M.cairo_set_antialias,
	set_fill_rule = M.cairo_set_fill_rule,
	set_line_width = M.cairo_set_line_width,
	set_line_cap = M.cairo_set_line_cap,
	set_line_join = M.cairo_set_line_join,
	set_dash = M.cairo_set_dash,
	set_miter_limit = M.cairo_set_miter_limit,
	translate = M.cairo_translate,
	scale = M.cairo_scale,
	rotate = M.cairo_rotate,
	rotate_around = M.cairo_rotate_around,
	scale_around = M.cairo_scale_around,
	transform = M.cairo_transform,
	safe_transform = M.cairo_safe_transform,
	set_matrix = M.cairo_set_matrix,
	identity_matrix = M.cairo_identity_matrix,
	skew = M.cairo_skew,
	user_to_device = M.cairo_user_to_device,
	user_to_device_distance = M.cairo_user_to_device_distance,
	device_to_user = M.cairo_device_to_user,
	device_to_user_distance = M.cairo_device_to_user_distance,
	new_path = M.cairo_new_path,
	move_to = M.cairo_move_to,
	new_sub_path = M.cairo_new_sub_path,
	line_to = M.cairo_line_to,
	curve_to = M.cairo_curve_to,
	quad_curve_to = M.cairo_quad_curve_to,
	arc = M.cairo_arc,
	arc_negative = M.cairo_arc_negative,
	circle = M.cairo_circle,
	ellipse = M.cairo_ellipse,
	--arc_to = M.cairo_arc_to, --abandoned? cairo_arc_to(x1, y1, x2, y2, radius)
	rel_move_to = M.cairo_rel_move_to,
	rel_line_to = M.cairo_rel_line_to,
	rel_curve_to = M.cairo_rel_curve_to,
	rel_quad_curve_to = M.cairo_rel_quad_curve_to,
	rectangle = M.cairo_rectangle,
	--stroke_to_path = M.cairo_stroke_to_path, --abandoned :(
	close_path = M.cairo_close_path,
	path_extents = M.cairo_path_extents,
	paint = M.cairo_paint,
	paint_with_alpha = M.cairo_paint_with_alpha,
	mask = M.cairo_mask,
	mask_surface = M.cairo_mask_surface,
	stroke = M.cairo_stroke,
	stroke_preserve = M.cairo_stroke_preserve,
	fill = M.cairo_fill,
	fill_preserve = M.cairo_fill_preserve,
	copy_page = M.cairo_copy_page,
	show_page = M.cairo_show_page,
	in_stroke = M.cairo_in_stroke,
	in_fill = M.cairo_in_fill,
	in_clip = M.cairo_in_clip,
	stroke_extents = M.cairo_stroke_extents,
	fill_extents = M.cairo_fill_extents,
	reset_clip = M.cairo_reset_clip,
	clip = M.cairo_clip,
	clip_preserve = M.cairo_clip_preserve,
	clip_extents = M.cairo_clip_extents,
	copy_clip_rectangle_list = M.cairo_copy_clip_rectangle_list,
	select_font_face = M.cairo_select_font_face,
	set_font_size = M.cairo_set_font_size,
	set_font_matrix = M.cairo_set_font_matrix,
	get_font_matrix = M.cairo_get_font_matrix,
	set_font_options = M.cairo_set_font_options,
	get_font_options = M.cairo_get_font_options,
	set_font_face = M.cairo_set_font_face,
	get_font_face = M.cairo_get_font_face,
	set_scaled_font = M.cairo_set_scaled_font,
	get_scaled_font = M.cairo_get_scaled_font,
	show_text = M.cairo_show_text,
	show_glyphs = M.cairo_show_glyphs,
	show_text_glyphs = M.cairo_show_text_glyphs,
	text_path = M.cairo_text_path,
	glyph_path = M.cairo_glyph_path,
	text_extents = M.cairo_text_extents,
	glyph_extents = M.cairo_glyph_extents,
	font_extents = M.cairo_font_extents,
	get_operator = M.cairo_get_operator,
	get_source = M.cairo_get_source,
	get_tolerance = M.cairo_get_tolerance,
	get_antialias = M.cairo_get_antialias,
	has_current_point = M.cairo_has_current_point,
	get_current_point = M.cairo_get_current_point,
	get_fill_rule = M.cairo_get_fill_rule,
	get_line_width = M.cairo_get_line_width,
	get_line_cap = M.cairo_get_line_cap,
	get_line_join = M.cairo_get_line_join,
	get_miter_limit = M.cairo_get_miter_limit,
	get_dash_count = M.cairo_get_dash_count,
	get_dash = M.cairo_get_dash,
	get_matrix = M.cairo_get_matrix,
	get_target = M.cairo_get_target,
	get_group_target = M.cairo_get_group_target,
	copy_path = M.cairo_copy_path,
	copy_path_flat = M.cairo_copy_path_flat,
	append_path = M.cairo_append_path,
	status = M.cairo_status,
	status_string = status_string,
}})

ffi.metatype('cairo_surface_t', {__index = {
	create_context = M.cairo_create,
	create_similar = M.cairo_surface_create_similar,
	create_similar_image = M.cairo_surface_create_similar_image,
	create_for_rectangle = M.cairo_surface_create_for_rectangle,
	reference = M.cairo_surface_reference,
	finish = M.cairo_surface_finish,
	destroy = M.cairo_surface_destroy,
	free = free_ref_counted,
	get_device = M.cairo_surface_get_device,
	get_reference_count = M.cairo_surface_get_reference_count,
	status = M.cairo_surface_status,
	status_string = status_string,
	get_type = M.cairo_surface_get_type,
	get_content = M.cairo_surface_get_content,
	write_to_png = M.cairo_surface_write_to_png,
	write_to_png_stream = M.cairo_surface_write_to_png_stream,
	get_user_data = M.cairo_surface_get_user_data,
	set_user_data = M.cairo_surface_set_user_data,
	get_mime_data = M.cairo_surface_get_mime_data,
	set_mime_data = M.cairo_surface_set_mime_data,
	get_font_options = M.cairo_surface_get_font_options,
	flush = M.cairo_surface_flush,
	mark_dirty = M.cairo_surface_mark_dirty,
	mark_dirty_rectangle = M.cairo_surface_mark_dirty_rectangle,
	set_device_offset = M.cairo_surface_set_device_offset,
	get_device_offset = M.cairo_surface_get_device_offset,
	set_fallback_resolution = M.cairo_surface_set_fallback_resolution,
	get_fallback_resolution = M.cairo_surface_get_fallback_resolution,
	copy_page = M.cairo_surface_copy_page,
	show_page = M.cairo_surface_show_page,
	has_show_text_glyphs = M.cairo_surface_has_show_text_glyphs,
	create_pattern = M.cairo_pattern_create_for_surface,
	apply_alpha = M.cairo_surface_apply_alpha,

	--for image surfaces
	get_image_data = M.cairo_image_surface_get_data,
	get_image_format = M.cairo_image_surface_get_format,
	get_image_width = M.cairo_image_surface_get_width,
	get_image_height = M.cairo_image_surface_get_height,
	get_image_stride = M.cairo_image_surface_get_stride,
	get_image_bpp = M.cairo_image_surface_get_bpp,
	get_image_pixel_function = M.cairo_image_surface_get_pixel_function,
	set_image_pixel_function = M.cairo_image_surface_set_pixel_function,
}})

ffi.metatype('cairo_device_t', {__index = {
	reference = M.cairo_device_reference,
	get_type = M.cairo_device_get_type,
	status = M.cairo_device_status,
	status_string = status_string,
	acquire = M.cairo_device_acquire,
	release = M.cairo_device_release,
	flush = M.cairo_device_flush,
	finish = M.cairo_device_finish,
	destroy = M.cairo_device_destroy,
	free = free_ref_counted,
	get_reference_count = M.cairo_device_get_reference_count,
	get_user_data = M.cairo_device_get_user_data,
	set_user_data = M.cairo_device_set_user_data,
}})

ffi.metatype('cairo_pattern_t', {__index = {
	reference = M.cairo_pattern_reference,
	destroy = M.cairo_pattern_destroy,
	free = free_ref_counted,
	get_reference_count = M.cairo_pattern_get_reference_count,
	status = M.cairo_pattern_status,
	status_string = status_string,
	get_user_data = M.cairo_pattern_get_user_data,
	set_user_data = M.cairo_pattern_set_user_data,
	get_type = M.cairo_pattern_get_type,
	add_color_stop_rgb = M.cairo_pattern_add_color_stop_rgb,
	add_color_stop_rgba = M.cairo_pattern_add_color_stop_rgba,
	set_matrix = M.cairo_pattern_set_matrix,
	get_matrix = M.cairo_pattern_get_matrix,
	set_extend = M.cairo_pattern_set_extend,
	get_extend = M.cairo_pattern_get_extend,
	set_filter = M.cairo_pattern_set_filter,
	get_filter = M.cairo_pattern_get_filter,
	get_rgba = M.cairo_pattern_get_rgba,
	get_surface = M.cairo_pattern_get_surface,
	get_color_stop_rgba = M.cairo_pattern_get_color_stop_rgba,
	get_color_stop_count = M.cairo_pattern_get_color_stop_count,
	get_linear_points = M.cairo_pattern_get_linear_points,
	get_radial_circles = M.cairo_pattern_get_radial_circles,
}})

ffi.metatype('cairo_scaled_font_t', {__index = {
	reference = M.cairo_scaled_font_reference,
	destroy = M.cairo_scaled_font_destroy,
	free = free_ref_counted,
	get_reference_count = M.cairo_scaled_font_get_reference_count,
	status = M.cairo_scaled_font_status,
	status_string = status_string,
	get_type = M.cairo_scaled_font_get_type,
	get_user_data = M.cairo_scaled_font_get_user_data,
	set_user_data = M.cairo_scaled_font_set_user_data,
	extents = M.cairo_scaled_font_extents,
	text_extents = M.cairo_scaled_font_text_extents,
	glyph_extents = M.cairo_scaled_font_glyph_extents,
	text_to_glyphs = M.cairo_scaled_font_text_to_glyphs,
	get_font_face = M.cairo_scaled_font_get_font_face,
	get_font_matrix = M.cairo_scaled_font_get_font_matrix,
	get_ctm = M.cairo_scaled_font_get_ctm,
	get_scale_matrix = M.cairo_scaled_font_get_scale_matrix,
	get_font_options = M.cairo_scaled_font_get_font_options,
}})

ffi.metatype('cairo_font_face_t', {__index = {
	reference = M.cairo_font_face_reference,
	destroy = M.cairo_font_face_destroy,
	free = free_ref_counted,
	get_reference_count = M.cairo_font_face_get_reference_count,
	status = M.cairo_font_face_status,
	status_string = status_string,
	get_type = M.cairo_font_face_get_type,
	get_user_data = M.cairo_font_face_get_user_data,
	set_user_data = M.cairo_font_face_set_user_data,
	create_scaled_font = M.cairo_scaled_font_create,
	toy_get_family = M.cairo_toy_font_face_get_family,
	toy_get_slant = M.cairo_toy_font_face_get_slant,
	toy_get_weight = M.cairo_toy_font_face_get_weight,
	user_set_init_func = M.cairo_user_font_face_set_init_func,
	user_set_render_glyph_func = M.cairo_user_font_face_set_render_glyph_func,
	user_set_text_to_glyphs_func = M.cairo_user_font_face_set_text_to_glyphs_func,
	user_set_unicode_to_glyph_func = M.cairo_user_font_face_set_unicode_to_glyph_func,
	user_get_init_func = M.cairo_user_font_face_get_init_func,
	user_get_render_glyph_func = M.cairo_user_font_face_get_render_glyph_func,
	user_get_text_to_glyphs_func = M.cairo_user_font_face_get_text_to_glyphs_func,
	user_get_unicode_to_glyph_func = M.cairo_user_font_face_get_unicode_to_glyph_func,
}})

ffi.metatype('cairo_font_options_t', {__index = {
	copy = M.cairo_font_options_copy,
	free = M.cairo_font_options_destroy,
	status = M.cairo_font_options_status,
	status_string = status_string,
	merge = M.cairo_font_options_merge,
	equal = M.cairo_font_options_equal,
	hash = M.cairo_font_options_hash,
	set_antialias = M.cairo_font_options_set_antialias,
	get_antialias = M.cairo_font_options_get_antialias,
	set_subpixel_order = M.cairo_font_options_set_subpixel_order,
	get_subpixel_order = M.cairo_font_options_get_subpixel_order,
	set_hint_style = M.cairo_font_options_set_hint_style,
	get_hint_style = M.cairo_font_options_get_hint_style,
	set_hint_metrics = M.cairo_font_options_set_hint_metrics,
	get_hint_metrics = M.cairo_font_options_get_hint_metrics,
	--private functions, only available in our custom build
	set_lcd_filter = if_exists'_cairo_font_options_set_lcd_filter',
	get_lcd_filter = if_exists'_cairo_font_options_get_lcd_filter',
	set_round_glyph_positions = if_exists'_cairo_font_options_set_round_glyph_positions',
	get_round_glyph_positions = if_exists'_cairo_font_options_get_round_glyph_positions',
}})

ffi.metatype('cairo_region_t', {__index = {
	create = M.cairo_region_create,
	create_rectangle = M.cairo_region_create_rectangle,
	create_rectangles = M.cairo_region_create_rectangles,
	copy = M.cairo_region_copy,
	reference = M.cairo_region_reference,
	destroy = M.cairo_region_destroy,
	free = free_ref_counted,
	equal = M.cairo_region_equal,
	status = M.cairo_region_status,
	status_string = status_string,
	get_extents = M.cairo_region_get_extents,
	num_rectangles = M.cairo_region_num_rectangles,
	get_rectangle = M.cairo_region_get_rectangle,
	is_empty = M.cairo_region_is_empty,
	contains_rectangle = M.cairo_region_contains_rectangle,
	contains_point = M.cairo_region_contains_point,
	translate = M.cairo_region_translate,
	subtract = M.cairo_region_subtract,
	subtract_rectangle = M.cairo_region_subtract_rectangle,
	intersect = M.cairo_region_intersect,
	intersect_rectangle = M.cairo_region_intersect_rectangle,
	union = M.cairo_region_union,
	union_rectangle = M.cairo_region_union_rectangle,
	xor = M.cairo_region_xor,
	xor_rectangle = M.cairo_region_xor_rectangle,
}})

ffi.metatype('cairo_path_t', {__index = {
	free = M.cairo_path_destroy,
}})

ffi.metatype('cairo_rectangle_list_t', {__index = {
	free = M.cairo_rectangle_list_destroy,
}})

ffi.metatype('cairo_glyph_t', {__index = {
	free = M.cairo_glyph_free,
}})
ffi.metatype('cairo_text_cluster_t', {__index = {
	free = M.cairo_text_cluster_free,
}})

local function cairo_matrix_tostring(mt)
	return string.format('[%12f%12f]\n[%12f%12f]\n[%12f%12f]',
		mt.xx, mt.yx, mt.xy, mt.yy, mt.x0, mt.y0)
end

ffi.metatype('cairo_matrix_t', {__index = {
	init = M.cairo_matrix_init,
	init_identity = M.cairo_matrix_init_identity,
	init_translate = M.cairo_matrix_init_translate,
	init_scale = M.cairo_matrix_init_scale,
	init_rotate = M.cairo_matrix_init_rotate,
	translate = M.cairo_matrix_translate,
	scale = M.cairo_matrix_scale,
	rotate = M.cairo_matrix_rotate,
	rotate_around = M.cairo_matrix_rotate_around,
	scale_around = M.cairo_matrix_scale_around,
	invert = M.cairo_matrix_invert,
	multiply = M.cairo_matrix_multiply,
	transform_distance = M.cairo_matrix_transform_distance,
	transform_point = M.cairo_matrix_transform_point,
	--additions
	transform = M.cairo_matrix_transform,
	invertible = M.cairo_matrix_invertible,
	safe_transform = M.cairo_matrix_safe_transform,
	skew = M.cairo_matrix_skew,
	copy = M.cairo_matrix_copy,
	init_matrix = M.cairo_matrix_init_matrix,
}, __tostring = cairo_matrix_tostring})

ffi.metatype('cairo_rectangle_int_t', {__index = {
	create_region = M.cairo_region_create_rectangle,
}})

return M
