
--Cairo binding for Terra based on cairo 1.12.3.
--Written by Cosmin Apreutesei. Public Domain.

setfenv(1, require'terra.low'.module())

require_h'cairo_h'
linklibrary'cairo'
local bitmap = require'terra.bitmap'

local function retbool(t, name, f)
	t['_'..name] = f
	t[name] = macro(function(self, ...)
		local args = {...}
		return `[bool](self:['_'..name](args))
	end)
end

local struct cairo_argb32_color_channels_t {
	alpha : uint8;
	blue  : uint8;
	green : uint8;
	red   : uint8;
}

local struct cairo_argb32_color_t {
	union {
		uint: uint32;
		channels: cairo_argb32_color_channels_t;
	}
}
C.cairo_argb32_color_t = cairo_argb32_color_t
forwardproperties('channels')(cairo_argb32_color_t)

cairo_argb32_color_t.metamethods.__cast = function(from, to, exp)
	if to == cairo_argb32_color_t then
		if from == uint32 or from == int32 then
			return `cairo_argb32_color_t {uint = exp}
		end
	elseif to == uint32 then
		if from == cairo_argb32_color_t then
			return `exp.uint
		end
	end
	assert(false, 'invalid conversion from ', from, ' to ', to, ': ', exp)
end

cairo_argb32_color_t.metamethods.__eq = macro(function(c1, c2)
	return `c1.uint == c2.uint
end)

cairo_argb32_color_t.metamethods.__ne = macro(function(c1, c2)
	return `not (c1 == c2)
end)

terra cairo_argb32_color_t:apply_alpha(a: num)
	var c = @self
	c.channels.alpha = c.channels.alpha * clamp(a, 0, 1)
	return c
end

local struct cairo_color_t {
	red:   double;
	green: double;
	blue:  double;
	alpha: double;
}
C.cairo_color_t = cairo_color_t

cairo_color_t.metamethods.__cast = function(from, to, exp)
	if to == cairo_color_t then
		if from == cairo_argb32_color_t then
			return `cairo_color_t {
				exp.channels.red   / 255.0,
				exp.channels.green / 255.0,
				exp.channels.blue  / 255.0,
				exp.channels.alpha / 255.0
			}
		end
	end
	assert(false, 'invalid conversion from ', from, ' to ', to, ': ', exp)
end

cairo_color_t.metamethods.__eq = macro(function(c1, c2)
	return `
		    c1.red   == c2.red
		and c1.green == c2.green
		and c1.blue  == c2.blue
		and c1.alpha == c2.alpha
end)

cairo_color_t.metamethods.__ne = macro(function(c1, c2)
	return not (c1 == c2)
end)

status_message = cairo_status_to_string

local cr = wrapopaque(cairo_t).methods

cr.ref           = cairo_reference
cr.free          = cairo_destroy
cr.refcount      = cairo_get_reference_count
cr.get_user_data = cairo_get_user_data
cr.set_user_data = cairo_set_user_data
cr.status        = cairo_status
cr.status_message = terra(self: &cairo_t) return status_message(self:status()) end
cr.save          = cairo_save
cr.restore       = cairo_restore
cr.push_group    = overload('push_group', {cairo_push_group, cairo_push_group_with_content})
cr.pop_group     = cairo_pop_group
cr.pop_group_to_source = cairo_pop_group_to_source
cr.target        = cairo_get_target
cr.group_target  = cairo_get_group_target

cr.operator    = overload('operator', {cairo_set_operator, cairo_get_operator})
cr.source      = overload('source',   {cairo_set_source, cairo_set_source_surface, cairo_get_source})
cr.rgb         = overload('rgb' , {cairo_set_source_rgb})
cr.rgba        = overload('rgba', {cairo_set_source_rgba})
cr.rgb:adddefinition(terra(self: &cairo_t, c: cairo_color_t)
	return self:rgb(unpackstruct(c, 1, 3))
end)
cr.rgba:adddefinition(terra(self: &cairo_t, c: cairo_color_t)
	return self:rgba(unpackstruct(c))
end)
cr.tolerance   = overload('tolerance',   {cairo_set_tolerance,   cairo_get_tolerance})
cr.antialias   = overload('antialias',   {cairo_set_antialias,   cairo_get_antialias})
cr.fill_rule   = overload('fill_rule',   {cairo_set_fill_rule,   cairo_get_fill_rule})
cr.line_width  = overload('line_width',  {cairo_set_line_width,  cairo_get_line_width})
cr.line_cap    = overload('line_cap',    {cairo_set_line_cap,    cairo_get_line_cap})
cr.line_join   = overload('line_join',   {cairo_set_line_join,   cairo_get_line_join})
cr.dash        = overload('dash',        {cairo_set_dash,        cairo_get_dash, cairo_get_dash_count})
cr.miter_limit = overload('miter_limit', {cairo_set_miter_limit, cairo_get_miter_limit})

cairo_matrix_t.identity = `cairo_matrix_t {1, 0, 0, 1, 0, 0}

local m = cairo_matrix_t.methods
m.init = overload('init', {
	cairo_matrix_init_identity,
	cairo_matrix_init,
})
m.determinant = terra(self: &cairo_matrix_t)
	return self.xx * self.yy - self.yx * self.xy
end
m.invertible = terra(self: &cairo_matrix_t)
	var det = self:determinant()
	return det ~= 0 and det ~= inf and det ~= -inf
end
m.translate = cairo_matrix_translate
m.scale = cairo_matrix_scale
m.rotate = cairo_matrix_rotate
m.invert = cairo_matrix_invert
m.distance = terra(self: &cairo_matrix_t, x: double, y: double)
	cairo_matrix_transform_distance(self, &x, &y); return x, y
end
m.point = terra(self: &cairo_matrix_t, x: double, y: double)
	cairo_matrix_transform_point(self, &x, &y); return x, y
end
m.multiply = overload('multiply', {
	cairo_matrix_multiply,
	terra(self: &cairo_matrix_t, m: &cairo_matrix_t)
		cairo_matrix_multiply(self, self, m)
	end,
})
m.transform = terra(self: &cairo_matrix_t, m: &cairo_matrix_t)
	self:multiply(m, self)
end
m.safe_transform = terra(self: &cairo_matrix_t, m: &cairo_matrix_t)
	if m:invertible() then self:transform(m) end
end
m.rotate_around = terra(self: &cairo_matrix_t, cx: double, cy: double, angle: double)
	self:translate(cx, cy)
	self:rotate(angle)
	self:translate(-cx, -cy)
end
m.scale_around = terra(self: &cairo_matrix_t, cx: double, cy: double, sx: double, sy: double)
	self:translate(cx, cy)
	self:scale(sx, sy)
	self:translate(-cx, -cy)
end
m.skew = terra(self: &cairo_matrix_t, ax: double, ay: double)
	var m: cairo_matrix_t; m:init()
	m.xy = tan(ax)
	m.yx = tan(ay)
	self:transform(&m)
end
m.copy = terra(self: &cairo_matrix_t)
	var m = @self; return m
end

cr.translate   = cairo_translate
cr.scale       = cairo_scale
cr.rotate      = cairo_rotate
cr.transform   = cairo_transform
cr.identity_matrix = cairo_identity_matrix
cr.matrix = overload('matrix', {
	cairo_set_matrix,
	terra(self: &cairo_t)
		var m: cairo_matrix_t
		cairo_get_matrix(self, &m)
		return m
	end,
})
cr.safe_transform = terra(self: &cairo_t, m: &cairo_matrix_t)
	if m:invertible() then self:transform(m) end
end
cr.rotate_around = terra(self: &cairo_t, cx: double, cy: double, angle: double)
	self:translate(cx, cy)
	self:rotate(angle)
	self:translate(-cx, -cy)
end
cr.scale_around = terra(self: &cairo_t, cx: double, cy: double, sx: double, sy: double)
	self:translate(cx, cy)
	self:scale(sx, sy)
	self:translate(-cx, -cy)
end
cr.skew = terra(self: &cairo_t, ax: double, ay: double)
	var m: cairo_matrix_t
	m:init()
	m.xy = tan(ax)
	m.yx = tan(ay)
	self:transform(&m)
end

cr.user_to_device          = cairo_user_to_device
cr.user_to_device_distance = cairo_user_to_device_distance
cr.device_to_user          = cairo_device_to_user
cr.device_to_user_distance = cairo_device_to_user_distance

cr.new_path       = cairo_new_path
cr.move_to        = cairo_move_to
cr.new_sub_path   = cairo_new_sub_path
cr.line_to        = cairo_line_to
cr.curve_to       = cairo_curve_to
cr.arc            = cairo_arc
cr.arc_negative   = cairo_arc_negative
cr.rel_move_to    = cairo_rel_move_to
cr.rel_line_to    = cairo_rel_line_to
cr.rel_curve_to   = cairo_rel_curve_to
cr.rectangle      = cairo_rectangle
cr.close_path     = cairo_close_path
cr.path_extents   = cairo_path_extents
cr.copy_path      = cairo_copy_path
cr.copy_path_flat = cairo_copy_path_flat
cr.append_path    = cairo_append_path

retbool(cr, 'has_current_point', cairo_has_current_point)
cr.current_point = terra(self: &cairo_t)
	var x: double
	var y: double
	cairo_get_current_point(self, &x, &y)
	return x, y
end

local p = cairo_path_t.methods
p.free = cairo_path_destroy

p.equal = terra(p1: &cairo_path_t, p2: &cairo_path_t)
	if p1.num_data ~= p2.num_data then return false end
	return equal(p1.data, p2.data, p1.num_data)
end

local path_node_type_names = {'move_to', 'line_to', 'curve_to', 'close_path'}
local path_node_types = constant(`arrayof(rawstring, path_node_type_names))

p.dump = terra(p: &cairo_path_t)
	pfn('cairo_path_t length: %d, status: %s',
		p.num_data,
		iif(p.status ~= CAIRO_STATUS_SUCCESS, status_message(p.status), 'ok'))
	var i = 0
	while i < p.num_data do
		var d = p.data[i]
		pf('\t%-12s', path_node_types[d.header.type])
		i = i + 1
		for j = 1, d.header.length do
			var d = p.data[i]
			pf('%g,%g ', d.point.x, d.point.y)
			i = i + 1
		end
		print()
	end
	return p
end

cr.circle = terra(self: &cairo_t, cx: double, cy: double, r: double)
	self:new_sub_path()
	self:arc(cx, cy, r, 0, 2 * PI)
	self:close_path()
end
cr.ellipse = terra(self: &cairo_t,
	cx: double, cy: double,
	rx: double, ry: double, rotation: double
)
	var m0 = self:matrix()
	self:translate(cx, cy)
	if rotation ~= 0 then
		self:rotate(rotation)
	end
	self:scale(1, [double](ry) / rx)
	self:circle(0, 0, rx)
	self:matrix(&m0)
end
local function elliptic_arc_func(arc)
	return terra(self: &cairo_t,
		cx: double, cy: double,
		rx: double, ry: double, rotation: double,
		a1: double, a2: double
	)
		if rx == 0 or ry == 0 then
			if self:has_current_point() then
				self:line_to(cx, cy)
			end
		elseif rx ~= ry or rotation ~= 0 then
			self:save()
			self:translate(cx, cy)
			self:rotate(rotation)
			self:scale([double](rx) / ry, 1)
			self:[arc](0, 0, ry, a1, a2)
			self:restore()
		else
			self:[arc](cx, cy, ry, a1, a2)
		end
	end
end
cr.elliptic_arc = elliptic_arc_func'arc'
cr.elliptic_arc_negative = elliptic_arc_func'arc_negative'

cr.quad_curve_to = terra(self: &cairo_t, x1: double, y1: double, x2: double, y2: double)
	var x0, y0 = self:current_point()
	self:curve_to(
		(x0 + 2 * x1) / 3.0,
		(y0 + 2 * y1) / 3.0,
		(x2 + 2 * x1) / 3.0,
		(y2 + 2 * y1) / 3.0,
		x2, y2)
end

cr.rel_quad_curve_to = terra(self: &cairo_t, x1: double, y1: double, x2: double, y2: double)
	var x0, y0 = self:current_point()
	self:quad_curve_to(x0+x1, y0+y1, x0+x2, y0+y2)
end

cr.paint = cairo_paint
cr.paint_with_alpha = cairo_paint_with_alpha
cr.mask = overload('mask', {cairo_mask, cairo_mask_surface})

cr.stroke          = cairo_stroke
cr.stroke_preserve = cairo_stroke_preserve
cr.fill            = cairo_fill
cr.fill_preserve   = cairo_fill_preserve

retbool(cr, 'in_stroke', cairo_in_stroke)
retbool(cr, 'in_fill'  , cairo_in_fill)
retbool(cr, 'in_clip'  , cairo_in_clip)

cr.stroke_extents = cairo_stroke_extents
cr.fill_extents   = cairo_fill_extents

cr.reset_clip    = cairo_reset_clip
cr.clip          = cairo_clip
cr.clip_preserve = cairo_clip_preserve
cr.clip_extents  = terra(self: &cairo_t)
	var x1: double, y1: double, x2: double, y2: double
	cairo_clip_extents(self, &x1, &y1, &x2, &y2)
	return x1, y1, x2, y2
end

cr.copy_clip_rectangle_list = cairo_copy_clip_rectangle_list

local rl = cairo_rectangle_list_t.methods
rl.free = cairo_rectangle_list_destroy

local s = wrapopaque(cairo_surface_t).methods

s.context  = cairo_create
s.ref      = cairo_surface_reference
s.refcount = cairo_surface_get_reference_count
s.status   = cairo_surface_status
s.free     = cairo_surface_destroy
s.get_user_data = cairo_surface_get_user_data
s.set_user_data = cairo_surface_set_user_data
s.finish   = cairo_surface_finish
s.device   = cairo_surface_get_device
s.type     = cairo_surface_get_type
s.content  = cairo_surface_get_content
s.flush    = cairo_surface_flush
s.mark_dirty = cairo_surface_mark_dirty
s.mark_dirty_rectangle = cairo_surface_mark_dirty_rectangle
s.data   = cairo_image_surface_get_data
s.format = cairo_image_surface_get_format
s.width  = cairo_image_surface_get_width
s.height = cairo_image_surface_get_height
s.stride = cairo_image_surface_get_stride

extern('cairo_surface_create_from_png', {rawstring} -> {&cairo_surface_t})
extern('cairo_surface_write_to_png', {&cairo_surface_t, rawstring} -> {cairo_status_t})
s.save_png = cairo_surface_write_to_png

s.apply_alpha = terra(self: &cairo_surface_t, alpha: double)
	if alpha >= 1 then return end
	var cr = self:context()
	cr:rgba(0, 0, 0, alpha)
	cr:operator(CAIRO_OPERATOR_DEST_IN) --alphas are multiplied, dest. color is preserved
	cr:paint()
	cr:free()
end

--bitmap utils
terra C.cairo_bitmap_format(fmt: cairo_format_t)
	return [enum](iif(fmt == CAIRO_FORMAT_A8,
		bitmap.FORMAT_G8, iif(fmt == CAIRO_FORMAT_ARGB32,
			bitmap.FORMAT_ARGB32, bitmap.FORMAT_INVALID)))
end
terra C.cairo_format_for_bitmap_format(fmt: enum)
	return [cairo_format_t](iif(fmt == bitmap.FORMAT_G8,
		CAIRO_FORMAT_A8, iif(fmt == bitmap.FORMAT_ARGB32,
			CAIRO_FORMAT_ARGB32, CAIRO_FORMAT_INVALID)))
end
s.bitmap_format = terra(self: &cairo_surface_t)
	return cairo_bitmap_format(self:format())
end
s.copy = terra(self: &cairo_surface_t) --copy surface to bitmap
	var b = bitmap.new(self:width(), self:height(), self:bitmap_format(), self:stride())
	self:flush()
	copy(b.pixels, [&uint8](self:data()), self:stride() * self:height())
	return b
end
terra C.cairo_image_surface_create_for_bitmap(b: &bitmap.Bitmap)
	var fmt = cairo_format_for_bitmap_format(b.format)
	return cairo_image_surface_create_for_data(b.pixels, fmt, b.w, b.h, b.stride)
end
s.asbitmap = terra(self: &cairo_surface_t)
	var b: bitmap.Bitmap
	b.format = bitmap.valid_format(cairo_bitmap_format(self:format()))
	b.w = self:width()
	b.h = self:height()
	b.stride = self:stride()
	b.pixels = [&uint8](self:data())
	return b
end
terra bitmap.Bitmap:surface()
	return cairo_image_surface_create_for_bitmap(self)
end

local p = wrapopaque(cairo_pattern_t).methods
p.ref      = cairo_pattern_reference
p.free     = cairo_pattern_destroy
p.refcount = cairo_pattern_get_reference_count
p.status   = cairo_pattern_status
p.get_user_data = cairo_pattern_get_user_data
p.set_user_data = cairo_pattern_set_user_data
p.type = cairo_pattern_get_type

p.color_stop_rgb       = cairo_pattern_get_color_stop_rgb
p.color_stop_rgba      = cairo_pattern_get_color_stop_rgba
p.color_stop_count     = cairo_pattern_get_color_stop_count
p.add_color_stop_rgb   = overload('add_color_stop_rgb', {cairo_pattern_add_color_stop_rgb})
p.add_color_stop_rgb:adddefinition(terra(self: &cairo_pattern_t, offset: double, color: cairo_color_t)
	return self:add_color_stop_rgb(offset, unpackstruct(color, 1, 3))
end)
p.add_color_stop_rgb:adddefinition(terra(self: &cairo_pattern_t, offset: double, color: cairo_argb32_color_t)
	return self:add_color_stop_rgb(offset, [cairo_color_t](color))
end)
p.add_color_stop_rgba  = overload('add_color_stop_rgba', {cairo_pattern_add_color_stop_rgba})
p.add_color_stop_rgba:adddefinition(terra(self: &cairo_pattern_t, offset: double, color: cairo_color_t)
	return self:add_color_stop_rgba(offset, unpackstruct(color))
end)
p.add_color_stop_rgba:adddefinition(terra(self: &cairo_pattern_t, offset: double, color: cairo_argb32_color_t)
	return self:add_color_stop_rgba(offset, [cairo_color_t](color))
end)
p.linear_points        = cairo_pattern_get_linear_points
p.radial_circles       = cairo_pattern_get_radial_circles
p.surface              = cairo_pattern_get_surface

p.matrix = overload('matrix', {
	cairo_pattern_set_matrix,
	terra(self: &cairo_pattern_t)
		var m: cairo_matrix_t
		cairo_pattern_get_matrix(self, &m)
		return m
	end,
})

p.extend = overload('extend', {cairo_pattern_set_extend, cairo_pattern_get_extend})
p.filter = overload('filter', {cairo_pattern_set_filter, cairo_pattern_get_filter})

return C
