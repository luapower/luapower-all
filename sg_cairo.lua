--scene graph for cairo: renders a 2D scene graph on a cairo context.
--some modules are loaded on-demand: look for require() in the code.
local ffi = require'ffi'
local cairo = require'cairo'
local glue = require'glue'
local BaseSG = require'sg_base'
local path_cairo = require'path2d_cairo'

local SG = glue.update({}, BaseSG)

function SG:new(surface, cache)
	local o = BaseSG.new(self, cache)
	self.cr = surface:create_context()
	return o
end

function SG:free()
	self.cr:free()
	BaseSG.free(self)
	if self.freetype then self.freetype:free() end
end

SG.defaults = require'sg_2d'.defaults

local function cairo_sym(k) return cairo[k] end --raises an exception for invalid k's
local function cairo_enum(prefix) --eg. cairo_enum('CAIRO_OPERATOR_') -> t; t.over -> cairo.CAIRO_OPERATOR_OVER
	return setmetatable({}, {__index = function(t,k)
		local ok, sym = pcall(cairo_sym, prefix..k:upper())
		t[k] = ok and sym or nil
		return rawget(t,k)
	end})
end

local antialias_methods = cairo_enum'CAIRO_ANTIALIAS_'
local subpixel_orders = cairo_enum'CAIRO_SUBPIXEL_ORDER_'
local hint_styles = cairo_enum'CAIRO_HINT_STYLE_'
local hint_metrics = cairo_enum'CAIRO_HINT_METRICS_'

SG:state_value('font_options', function(self, e)
	local fopt = self.cache:get(e)
	if not fopt then
		fopt = cairo.cairo_font_options_create()
		fopt:set_antialias(antialias_methods[e.antialias or self.defaults.font_options.antialias])
		fopt:set_subpixel_order(subpixel_orders[e.subpixel_order or self.defaults.font_options.subpixel_order])
		fopt:set_hint_style(hint_styles[e.hint_style or self.defaults.font_options.hint_style])
		fopt:set_hint_metrics(hint_metrics[e.hint_metrics or self.defaults.font_options.hint_metrics])
		self.cache:set(e, fopt)
	end
	self.cr:font_options(fopt)
end)

local font_slants = cairo_enum'CAIRO_FONT_SLANT_'
local font_weights = cairo_enum'CAIRO_FONT_WEIGHT_'

local function font_file_free(ff)
	ff.cairo_face:free()
	ff.ft_face:free()
end

local function bitmask(consts, bits, prefix)
	if not vt then return 0 end
	local v = 0
	for k in pairs(bits) do
		v = bit.bor(v, consts[prefix..k:upper()])
	end
	return v
end

function SG:load_font_file(e) --for preloading
	if not e then return nil end
	local ff = self.cache:get(e)
	if not ff then
		local freetype = require'freetype'
		if not self.freetype then self.freetype = freetype.new() end
		local ft_face = self.freetype:new_face(e.path)
		local load_options = bitmask(freetype, e.load_options, 'FT_LOAD_')
		local cairo_face = cairo.cairo_ft_font_face_create_for_ft_face(ft_face, load_options)
		local ff_object = newproxy(true)
		getmetatable(ff_object).__index = {
			ft_face = ft_face,
			cairo_face = cairo_face,
			free = font_file_free,
		}
		getmetatable(ff_object).__gc = font_file_free
		self.cache:set(e, ff)
	end
	return ff
end

SG:state_value('font_file', function(self, e)
	self.cr:font_face(self:load_font_file(e))
end)

SG:state_value('font_size', function(self, size)
	self.cr:font_size(size)
end)

SG:state_value('font', function(self, font)
	if font.file then
		self:set_font_file(font.file)
	else
		self.cr:font_face(font.family or self.defaults.font.family,
								font_slants[font.slant or self.defaults.font.slant],
								font_weights[font.weight or self.defaults.font.weight])
	end
	self:set_font_options(font.options)
	self:set_font_size(font.size)
end)

SG:state_value('line_dashes', function(self, e)
	local d = self.cache:get(e)
	if not d then
		local a = #e > 0 and ffi.new('double[?]', #e, e) or nil
		d = {a = a, n = #e, offset = e.offset}
		self.cache:set(d)
	end
	self.cr:dash(d.a, d.n, d.offset or 0)
end)

SG:state_value('line_width', function(self, width)
	self.cr:line_width(width)
end)

--like state_value but use a lookup table; for invalid values, set the default value and record the error.
function SG:state_enum(k, enum, set) --too much abstraction?
	self:state_value(k, function(self, e)
		set(self, self:assert(enum[e], 'invalid %s %s', k, tostring(e)) or enum[self.defaults[k]])
	end)
end

SG:state_enum('line_cap', cairo_enum'CAIRO_LINE_CAP_', function(self, cap)
	self.cr:line_cap(cap)
end)

SG:state_enum('line_join', cairo_enum'CAIRO_LINE_JOIN_', function(self, join)
	self.cr:line_join(join)
end)

SG:state_value('miter_limit', function(self, limit)
	self.cr:miter_limit(limit)
end)

local fill_rules = {
	nonzero = cairo.CAIRO_FILL_RULE_WINDING,
   evenodd = cairo.CAIRO_FILL_RULE_EVEN_ODD,
}

SG:state_enum('fill_rule', fill_rules, function(self, rule)
	self.cr:fill_rule(rule)
end)

SG:state_enum('operator', cairo_enum'CAIRO_OPERATOR_', function(self, op)
	self.cr:operator(op)
end)

local function new_matrix(...)
	return ffi.new('cairo_matrix_t', ...)
end

function SG:transform(e)
	local tr
	if e.absolute then self.cr:identity_matrix(); tr = true end
	if e.matrix then self.cr:safe_transform(new_matrix(unpack(e.matrix))); tr = true end
	if e.x or e.y then self.cr:translate(e.x or 0, e.y or 0); tr = true end
	if e.cx or e.cy then self.cr:translate(e.cx or 0, e.cy or 0) end
	if e.angle then self.cr:rotate(math.rad(e.angle)); tr = true end
	if e.scale then self.cr:scale(e.scale, e.scale); tr = true end
	if e.sx or e.sy then self.cr:scale(e.sx or 1, e.sy or 1); tr = true end
	if e.cx or e.cy then self.cr:translate(-(e.cx or 0), -(e.cy or 0)) end
	if e.skew_x or e.skew_y then self.cr:skew(math.rad(e.skew_x or 0), math.rad(e.skew_y or 0)); tr = true end
	if e.transforms then
		for _,t in ipairs(e.transforms) do
			local op = t[1]
			if op == 'matrix' then
				self.cr:safe_transform(new_matrix(unpack(t, 2))); tr = true
			elseif op == 'translate' then
				self.cr:translate(t[2], t[3] or 0); tr = true
			elseif op == 'rotate' then
				local cx, cy = t[3], t[4]
				if cx or cy then self.cr:translate(cx or 0, cy or 0) end
				self.cr:rotate(math.rad(t[2])); tr = true
				if cx or cy then self.cr:translate(-(cx or 0), -(cy or 0)) end
			elseif op == 'scale' then
				self.cr:scale(t[2], t[3] or t[2]); tr = true
			elseif op == 'skew' then
				self.cr:skew(math.rad(t[2]), math.rad(t[3])); tr = true
			end
		end
	end
	if tr then self.current_path = nil end --transformations invalidate the current path
end

function SG:save()
	self.cr:save()
	return self:state_save()
end

function SG:restore(state)
	self.cr:restore()
	self:state_restore(state)
end

function SG:push_group()
	self.cr:push_group()
	return self:state_save()
end

function SG:pop_group(state)
	self:state_restore(state)
	return self.cr:pop_group()
end

function SG:pop_group_as_source(state)
	self:state_restore(state)
	return self.cr:pop_group_as_source()
end

function SG:draw_path(path)
	path_cairo(self.cr, path)
end

function SG:set_path(e)
	if self.current_path == e then return end --path is global state, not part of the state stack
	local path = self.cache:get(e)
	if not path then
		self:draw_path(e)
		path = self.cr:copy_path()
		self.cache:set(e, path)
	else
		self.cr:new_path()
		self.cr:append_path(path)
	end
	self.current_path = e
end

local function clamp01(x)
	return x < 0 and 0 or x > 1 and 1 or x
end

local function total_alpha(e, alpha)
	if not e or e.hidden then return 0 end
	return clamp01(e.alpha or 1) * clamp01(alpha or 1)
end

local unbounded_operators = glue.index{'in', 'out', 'dest_in', 'dest_atop'}

function SG:set_color_source(e, alpha)
	self.cr:rgba(e[1], e[2], e[3], (e[4] or 1) * alpha)
end

function SG:register_hit(e)
	if not self.hit_objects then self.hit_objects = {} end
	self.hit_objects[#self.hit_objects+1] = e
end

function SG:paint_color(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:set_color_source(e, alpha)
	self:set_operator(operator or e.operator)
	self.cr:paint()
end

function SG:fill_color(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:set_color_source(e, alpha)
	operator = operator or e.operator
	self:set_operator(operator)
	if unbounded_operators[operator] then
		self.cr:save()
		self.cr:clip_preserve()
		self.cr:paint()
		self.cr:restore()
	else
		self.cr:fill_preserve()
	end
end

function SG:stroke_color(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:set_color_source(e, alpha)
	self:set_operator(operator or e.operator)
	self.cr:stroke_preserve()
end

SG.pattern_filters = cairo_enum'CAIRO_FILTER_'
SG.pattern_extends = cairo_enum'CAIRO_EXTEND_'

local function pattern_free(patt)
	patt.pattern:free()
end

function SG:set_gradient_source(e, alpha)
	local patt = self.cache:get(e)
	local pat
	if not patt then
		if e.r1 then
			pat = cairo.cairo_pattern_create_radial(e.x1, e.y1, e.r1, e.x2, e.y2, e.r2)
		else
			pat = cairo.cairo_pattern_create_linear(e.x1, e.y1, e.x2, e.y2)
		end
		for i=1,#e,2 do
			local offset, c = e[i], e[i+1]
			pat:add_color_stop(offset, c[1], c[2], c[3], (c[4] or 1) * alpha)
		end
		pat:set_filter(self.pattern_filters[e.filter or self.defaults.gradient_filter])
		pat:set_extend(self.pattern_extends[e.extend or self.defaults.gradient_extend])
		local patt = newproxy(true)
		local patt_t = {pattern = pat, alpha = alpha}
		getmetatable(patt).__index = patt_t
		getmetatable(patt).__gc = pattern_free
		self.cache:set(e, patt)
	elseif patt.alpha ~= alpha then
		self.cache:release(patt)
		return self:set_gradient_source(e, alpha)
	else
		pat = patt.pattern
	end
	if e.relative then --fill follows the bounding box of the shape on which it is applied
		assert(self.shape_bounding_box, 'relative fill not inside a shape')
		local bx1, by1, bx2, by2 = unpack(self.shape_bounding_box)
		local x, y, w, h = bx1, by1, bx2-bx1, by2-by1
		pat:set_matrix(new_matrix(1/w, 0, 0, 1/h, -x/w, -y/h))
	end
	self.cr:source(pat)
end

function SG:paint_gradient(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_gradient_source(e, 1)
	self:set_operator(operator or e.operator)
	self.cr:paint_with_alpha(alpha)
end

function SG:fill_gradient(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_gradient_source(e, 1)
	operator = operator or e.operator
	self:set_operator(operator)
	if alpha == 1 and not unbounded_operators[operator] then
		self.cr:fill_preserve()
	else
		self.cr:save()
		self.cr:clip_preserve()
		self.cr:paint_with_alpha(alpha)
		self.cr:restore()
	end
end

function SG:stroke_gradient(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_gradient_source(e, alpha)
	self:set_operator(operator or e.operator)
	self.cr:stroke_preserve()
end

local function image_source_free(source)
	source.surface:free()
end

local imagefile_load_options = {
		accept = ffi.abi'le' and
			{top_down = true, bgra = true} or
			{top_down = true, argb = true}
}

function SG:load_image_file(e, alpha)
	alpha = alpha or 1
	local source = self.cache:get(e)
	if not source then
		--load image
		local imagefile = require'imagefile'
		local img = self:assert(glue.protect(imagefile.load)(e, imagefile_load_options))
		if not img then return end
		--link image bits to a surface
		local surface = cairo.cairo_image_surface_create_for_data(img.data,
									cairo.CAIRO_FORMAT_ARGB32, img.w, img.h, img.w * 4)
		if surface:status() ~= 0 then
			self:error(surface:status_string())
			surface:free()
			return
		end
		surface:apply_alpha(alpha)
		--cache it, alnong with the image bits which we need to keep around
		source = newproxy(true)
		local source_t = {
			surface = surface,
			data = img.data,
			alpha = alpha,
			w = img.w, h = img.h,
			free = image_source_free
		}
		getmetatable(source).__index = source_t
		getmetatable(source).__gc = image_source_free
		self.cache:set(e, source)
	elseif source.alpha ~= alpha then --if it has a different alpha, it's invalid
		self.cache:release(e)
		return self:load_image_file(e, alpha)
	end
	return source
end

function SG:set_image_source(e, alpha)
	local source = self:load_image_file(e.file, alpha)
	if not source then return end
	self.cr:source(source.surface, 0, 0)
	local pat = self.cr:get_source()
	pat:set_filter(self.pattern_filters[e.filter or self.defaults.image_filter])
	pat:set_extend(self.pattern_extends[e.extend or self.defaults.image_extend])
end

function SG:paint_image(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_image_source(e, 1)
	self:set_operator(operator or e.operator)
	self.cr:paint_with_alpha(alpha)
end

function SG:fill_image(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_image_source(e, 1)
	operator = operator or e.operator
	self:set_operator(operator)
	if alpha == 1 and not unbounded_operators[operator] then
		self.cr:fill_preserve()
	else
		self.cr:save()
		self.cr:clip_preserve()
		self.cr:paint_with_alpha(alpha)
		self.cr:restore()
	end
end

function SG:stroke_image(e, alpha, operator)
	alpha = total_alpha(e, alpha)
	if alpha == 0 then return end
	self:transform(e)
	self:set_image_source(e, alpha)
	self:set_operator(operator or e.operator)
	self.cr:stroke_preserve()
end

function SG:set_stroke_options(e)
	if not e.stroke then return end
	self:set_line_width(e.line_width)
	self:set_line_cap(e.line_cap)
	self:set_line_join(e.line_join)
	self:set_miter_limit(e.miter_limit)
	self:set_line_dashes(e.line_dashes)
end

function SG:is_simple_shape(e)
	if e.type ~= 'shape' then return end
	local ftype = e.fill and not e.fill.hidden and e.fill.type
	local stype = e.stroke and not e.stroke.hidden and e.stroke.type
	if not ftype and not stype then return true end
	return
		((ftype and not stype) or (stype and not ftype)) --stroke + fill means composite
		and (not ftype or ftype == 'color' or ftype == 'gradient' or ftype == 'image') --no fill or non-composite fill
		and (not stype or stype == 'color' or stype == 'gradient' or stype == 'image') --no stroke or non-composite stroke
		and ((e.operator or self.defaults.operator) == 'over' or
				((not ftype or (e.fill.operator or self.defaults.operator) == 'over') and
				(not stype or (e.stroke.operator or self.defaults.operator) == 'over'))) --no operator or no sub-operator
end

function SG:paint_simple_shape(e)
	local alpha = total_alpha(e)
	if alpha == 0 then return end
	local operator = e.operator or self.defaults.operator
	if operator == 'over' then operator = nil end
	self:transform(e)
	self:set_path(e.path)
	if e.fill then
		self:set_fill_rule(e.fill_rule)
		if e.fill.type == 'gradient' and e.fill.relative then
			self.shape_bounding_box = {self.cr:path_extents()}
		end
		if e.fill.type == 'color' then
			self:fill_color(e.fill, alpha, operator)
		elseif e.fill.type == 'gradient' then
			self:fill_gradient(e.fill, alpha, operator)
		elseif e.fill.type == 'image' then
			self:fill_image(e.fill, alpha, operator)
		end
	elseif e.stroke then
		self:set_stroke_options(e)
		if e.stroke.type == 'color' then
			self:stroke_color(e.stroke, alpha, operator)
		elseif e.stroke.type == 'gradient' then
			self:stroke_gradient(e.stroke, alpha, operator)
		elseif e.stroke.type == 'image' then
			self:stroke_image(e.stroke, alpha, operator)
		end
	end
end

-- time to get recursive: composite objects

function SG:paint(e)
	if e.type == 'color' then
		self:paint_color(e)
	elseif e.type == 'gradient' then
		self:paint_gradient(e)
	elseif e.type == 'image' then
		self:paint_image(e)
	elseif self:is_simple_shape(e) then
		self:paint_simple_shape(e)
	else
		self:paint_composite(e)
	end
end

function SG:fill(e)
	if e.type == 'color' then
		self:fill_color(e)
	elseif e.type == 'gradient' then
		self:fill_gradient(e)
	elseif e.type == 'image' then
		self:fill_image(e)
	else
		self:fill_composite(e)
	end
end

function SG:stroke(e)
	if e.type == 'color' then
		self:stroke_color(e)
	elseif e.type == 'gradient' then
		self:stroke_gradient(e)
	elseif e.type == 'image' then
		self:stroke_image(e)
	else
		self:stroke_composite(e)
	end
end

function SG:paint_composite(e)
	local alpha = total_alpha(e)
	if alpha == 0 then return end
	self:transform(e)
	if alpha == 1 and ((e.operator or self.defaults.operator) == 'over') then
		self:draw_composite(e)
	elseif self:is_simple_shape(e) then
		self:paint_simple_shape(e)
	else
		local state = self:push_group()
		self:draw_composite(e)
		local source = self:pop_group(state)
		self.cr:source(source)
		self:set_operator(e.operator)
		self.cr:paint_with_alpha(alpha)
		self.cr:rgb(0,0,0) --release source from cr so we can free it
		source:free()
	end
end

function SG:fill_composite(e)
	if total_alpha(e) == 0 then return end
	local state = self:save()
	self.cr:clip_preserve()
	self:paint_composite(e)
	self:restore(state)
end

function SG:stroke_composite(e)
	alpha = total_alpha(e)
	if alpha == 0 then return end
	self:transform(e)
	local state = self:push_group()
	self:draw_composite(e)
	local source = self:pop_group(state)
	source:get_surface():apply_alpha(alpha)
	self.cr:source(source)
	self:set_operator(e.operator)
	self.cr:stroke_preserve()
	self.cr:rgb(0,0,0) --release source from cr so we can free it
	source:free()
end

SG.ext_draw = {} --{object_type = draw_function(e)}

function SG:draw_composite(e)
	if e.type == 'group' then
		self:draw_group(e)
	elseif e.type == 'shape' then
		self:draw_shape(e)
	elseif e.type == 'svg' then
		self:draw_svg(e)
	elseif self.ext_draw[e.type] then
		self.ext_draw[e.type](self, e)
	elseif e.type then
		self:error('unknown object type %s ', tostring(e.type))
	else
		self:error'object type expected'
	end
end

function SG:draw_group(e)
	local mt = self.cr:get_matrix()
	for i=1,#e do
		self:paint(e[i])
		self.cr:matrix(mt)
		self.current_path = nil
	end
end

function SG:draw_shape(e)
	local mt = self.cr:get_matrix()
	self:set_path(e.path)
	if e.fill and e.fill.type == 'gradient' and e.fill.relative then
		self.shape_bounding_box = {self.cr:path_extents()}
	end
	if e.stroke_first then
		if e.stroke then
			self:set_stroke_options(e)
			self:stroke(e.stroke)
			if e.fill then
				self.cr:matrix(mt)
				self.current_path = nil
				self:set_path(e.path)
			end
		end
		if e.fill then
			self:set_fill_rule(e.fill_rule)
			self:fill(e.fill)
		end
	else
		if e.fill then
			self:set_fill_rule(e.fill_rule)
			self:fill(e.fill)
			if e.stroke then
				self.cr:matrix(mt)
				self.current_path = nil
				self:set_path(e.path)
			end
		end
		if e.stroke then
			self:set_stroke_options(e)
			self:stroke(e.stroke)
		end
	end
end

function SG:load_svg_file(e)
	local object = self.cache:get(e)
	if not object then
		local svg_parser = require'svg_parser'
		object = svg_parser.parse(e)
		self.cache:set(e, object)
	end
	return object
end

function SG:draw_svg(e)
	self:paint(self:load_svg_file(e.file))
end

--public API

function SG:get_image_size(e)
	local source = self:load_image_file(e.file)
	return source.w, source.h
end

function SG:get_svg_object(e) --the object can be modified between frames as long as the svg is not invalidated
	return self:load_svg_file(e.file)
end

function SG:render(e)
	self.cr:identity_matrix()
	self:paint(e)
	self.cr:rgb(0,0,0) --release source, if any
	self:set_font_file(nil) --release font, if any
	if self.cr:status() ~= 0 then --see if cairo didn't shutdown
		self:error(self.cr:status_string())
	end
	self:errors_flush()
end

function SG:preload(e)
	if e.type == 'group' then
		for _,e in ipairs(e) do
			self:preload(e)
		end
	elseif e.type == 'image' then
		self:load_image_file(e.file)
	elseif e.type == 'svg' then
		self:load_svg_file(e.file)
	elseif e.type == 'shape' then
		if e.fill then self:preload(e.fill) end
		if e.stroke then self:preload(e.stroke) end
		for i=1,#e.path do
			if e.path[i] == 'text' and e.path[i+1].file then
				self:load_font_file(e.path[i+1].file)
			end
		end
	end
	self:errors_flush()
end

--measuring API

function SG:box_to_device(x1,y1,x2,y2)
	local dx1,dy1 = self.cr:user_to_device(x1,y1)
	local dx2,dy2 = self.cr:user_to_device(x2,y2)
	local dx3,dy3 = self.cr:user_to_device(x1,y2)
	local dx4,dy4 = self.cr:user_to_device(x2,y1)
	return
		math.min(dx1,dx2,dx3,dx4), math.min(dy1,dy2,dy3,dy4),
		math.max(dx1,dx2,dx3,dx4), math.max(dy1,dy2,dy3,dy4)
end

function SG:measure_image(e)
	local source = self:load_image_file(e.file)
	return self:box_to_device(0,0,source.w,source.h)
end

function SG:measure_shape(e)
	self:set_path(e.path)
	if e.stroke then
		self:set_line_width(e.line_width)
		self:set_line_cap(e.line_cap)
		self:set_line_join(e.line_join)
		self:set_miter_limit(e.miter_limit)
		self:set_line_dashes(e.line_dashes)
		self.cr:identity_matrix()
		return self.cr:path_extents()
	else
		self.cr:identity_matrix()
		return self.cr:path_extents()
	end
end

function SG:measure_group(e)
	local mt = self.cr:get_matrix()
	local dx1,dy1,dx2,dy2 = math.huge, math.huge, -math.huge, -math.huge
	for i=1,#e do
		local x1,y1,x2,y2 = self:measure_object(e[i])
		if x1 then
			dx1, dy1 = math.min(dx1,x1), math.min(dy1,y1)
			dx2, dy2 = math.max(dx2,x2), math.max(dy2,y2)
		end
		self.cr:matrix(mt)
	end
	if dx1 == math.huge then return end
	return dx1,dy1,dx2,dy2
end

SG.ext_measure = {} --{object_type = measure_function(e) -> x1, y1, x2, y2}

function SG:measure_object(e)
	self:transform(e)
	if e.type == 'group' then
		return self:measure_group(e)
	elseif e.type == 'shape' then
		return self:measure_shape(e)
	elseif e.type == 'svg' then
		return self:measure_svg(e)
	elseif e.type == 'image' then
		return self:measure_image(e)
	elseif self.ext_measure[e.type] then
		return self.ext_measure[e.type](self, e)
	end
end

function SG:measure_svg(e)
	return self:measure_object(self:load_svg_file(e.file))
end

function SG:measure(e)
	self.cr:identity_matrix()
	return self:measure_object(e)
end

--hit testing API

function SG:hit_test(x, y, e)

	local elements = {} --{e = true}

	local function test(e)
		local alpha = total_alpha(e)
		if alpha == 0 then return end
		self:transform(e)

		local ux, uy = self.cr:device_to_user(x, y)
		if not self.cr:in_clip(ux, uy) then return end

		local hit

		if e.type == 'group' then
			local mt = self.cr:get_matrix()
			for i=#e,1,-1 do
				hit = test(e[i])
				if hit then break end --don't look below the topmost element that was hit
				self.cr:matrix(mt)
				self.current_path = nil
			end
		elseif e.type == 'shape' then
			self:set_path(e.path)

			self:set_fill_rule(e.fill_rule)
			self:set_stroke_options(e)

			if e.stroke and self.cr:in_stroke(ux, uy)
				and (not e.stroke_first or (not e.fill or not self.cr:in_fill(ux, uy)))
			then
				hit = test(e.stroke)
			end

			if e.fill and self.cr:in_fill(ux, uy) then
				self.cr:save()
				self.cr:clip_preserve()
				hit = test(e.fill) or hit
				self.cr:restore()
			end

		elseif e.type == 'color' then
			hit = true
		elseif e.type == 'gradient' then
			--TODO: if extend is none, compute the real bounds (can be tricky)
			hit = true
		elseif e.type == 'image' then
			if (e.extend or self.defaults.image_extend) == 'none' then
				local w, h = self:get_image_size(e)
				hit = ux >= 0 and ux <= w and uy >= 0 and uy <= h
			else
				hit = true
			end
		elseif e.type == 'svg' then
			hit = test(self:get_svg_object(e))
		end

		if hit then
			elements[e] = true
			return true
		end
	end

	self.cr:identity_matrix()
	test(e)
	return elements
end

if not ... then require'sg_cairo_demo' end

return SG
