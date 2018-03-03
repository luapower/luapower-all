
--extensible UI toolkit with layouts, styles and animations.
--Written by Cosmin Apreutesei. Public Domain.

local oo = require'oo'
local glue = require'glue'
local tuple = require'tuple'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local time = require'time'
local gfonts = require'gfonts'
local freetype = require'freetype'
local cairo = require'cairo'

local push = table.insert
local pop = table.remove
local indexof = glue.indexof
local update = glue.update
local attr = glue.attr
local lerp = glue.lerp
local clamp = glue.clamp
local assert = glue.assert
local collect = glue.collect

local function str(s)
	return type(s) == 'string' and glue.trim(s) or nil
end

local function round(x)
	return math.floor(x + 0.5)
end

local function default(x, default)
	if x == nil then
		return default
	else
		return x
	end
end

--object system --------------------------------------------------------------

local object = oo.object()

--speed up class field lookup by converting subclassing to static
--inheritance. note: runtime patching of non-final classes still works.
function object:override_subclass(inherited, ...)
	return inherited(self, ...):inherit(self)
end

--speed up virtual property lookup without detaching instances completely
--which would make instances too fat.
function object:before_init()
	self.__setters = self.__setters
	self.__getters = self.__getters
end

--module object --------------------------------------------------------------

local ui = oo.ui(object)
ui.object = object

--drawing contexts -----------------------------------------------------------

ui.draw = oo.draw(ui.object)
local dr = ui.draw

function dr:init(ui)
	self.ui = ui
end

--fill & stroke

function ui:after_init()
	self._colors = {} --{'#rgba' -> {r, g, b, a}}
end

function ui:color(c)
	if type(c) == 'string' then
		local t = self._colors[c]
		if not t then
			t = {color.string_to_rgba(c)}
			self._colors[c] = t
		end
		return unpack(t)
	else
		return unpack(c)
	end
end

function dr:_setcolor(color)
	self.cr:rgba(self.ui:color(color))
end

function dr:_fill(color)
	self:_setcolor(color)
	self.cr:fill()
end

function dr:_stroke(color, line_width)
	self:_setcolor(color)
	self.cr:line_width(line_width)
	self.cr:stroke()
end

function dr:_fillstroke(fill_color, stroke_color, line_width)
	if fill_color and stroke_color then
		self:_setcolor(fill_color)
		self.cr:fill_preserve()
		self:_stroke(stroke_color, line_width)
	elseif fill_color then
		self:_fill(fill_color)
	elseif stroke_color then
		self:_stroke(stroke_color, line_width)
	else
		self:_fill()
	end
end

function dr:_paint(color)
	self:_setcolor(color)
	self.cr:paint()
end

--curent matrix

function dr:translate(x, y)
	self.cr:translate(x, y)
end

function dr:push_translate(x, y)
	self.cr:save()
	self.cr:translate(x, y)
end

function dr:pop_translate()
	self.cr:restore()
end

--clipping

function dr:push_cliprect(x, y, w, h)
	local cr = self.cr
	cr:save()
	cr:translate(x, y)
	cr:rectangle(0, 0, w, h)
	cr:clip()
end

function dr:pop_cliprect()
	self.cr:restore()
end

--shapes

function dr:rect(x, y, w, h, ...)
	self.cr:rectangle(x, y, w, h)
	self:_fillstroke(...)
end

function dr:border(x, y, w, h, color, b)
	self.cr:rectangle(x-b/2, y-b/2, w+b, h+b)
	self:_stroke(color, b)
end

function dr:dot(x, y, r, ...)
	self:rect(x-r, y-r, 2*r, 2*r, ...)
end

function dr:circle(x, y, r, ...)
	self.cr:circle(x, y, r)
	self:_fillstroke(...)
end

function dr:line(x1, y1, x2, y2, ...)
	self.cr:move_to(x1, y1)
	self.cr:line_to(x2, y2)
	self:_stroke(...)
end

function dr:curve(x1, y1, x2, y2, x3, y3, x4, y4, ...)
	self.cr:move_to(x1, y1)
	self.cr:curve_to(x2, y2, x3, y3, x4, y4)
	self:_stroke(...)
end

--text

function ui:after_init()
	self._freetype = freetype:new()
	self._font_files = {} --{(family, weight, slant) -> file}
	self._font_faces = {} --{file -> {ft_face=, cr_face=}}
end

function ui:before_free()
	for _,face in pairs(self._font_faces) do
		--can't free() it because cairo's cache is lazy.
		--cairo will free the freetype face object on its own.
		face.cr_face:unref()
	end
	self._font_faces = nil
	--safe to free() the freetype object here because cr_face holds a reference
	--to the FT_Library and will call FT_Done_Library() on its destructor.
	self._freetype:free()
end

function dr:before_free()
	self.cr:font_face(cairo.NULL)
end

--override this for different ways of finding font files
function ui:_font_file(family, weight, slant)
	return gfonts.font_file(family, weight, slant)
end

--override this for different ways of loading fonts
function ui:_font_face(family, weight, slant)
	local id = tuple(family, weight, slant)
	local file = self._font_files[id]
	if not file then
		file = assert(self:_font_file(family, weight, slant),
			'could not find a font for "%s, %s, %s"', family, weight, slant)
		self._font_files[id] = file
	end
	local face = self._font_faces[file]
	if not face then
		face = {}
		face.ft_face = self._freetype:face(file)
		face.cr_face = assert(cairo.ft_font_face(face.ft_face))
		self._font_faces[file] = face
	end
	return face
end

--override this for different ways of setting a loaded font
function dr:_setfont(family, weight, slant, size)
	local face = self.ui:_font_face(family, weight, slant)
	self.cr:font_face(face.cr_face)
	self.cr:font_size(size)
	local ext = self.cr:font_extents()
	self._font_height = ext.height
	self._font_descent = ext.descent
	self._font_ascent = ext.ascent
end

--multi-line self-aligned and box-aligned text

function dr:_line_extents(s)
	local ext = self.cr:text_extents(s)
	return ext.width, ext.height, ext.y_bearing
end

function dr:textbox(x, y, w, h, s,
	font_family, font_weight, font_slant, text_size, line_spacing, text_color,
	halign, valign)

	self:_setfont(font_family, font_weight, font_slant, text_size)
	self:_setcolor(text_color)

	self:push_cliprect(x, y, w, h)

	local cr = self.cr

	local line_h = self._font_height * line_spacing

	if halign == 'right' then
		x = w
	elseif not halign or halign == 'center' then
		x = round(w / 2)
	else
		x = 0
	end

	if valign == 'top' then
		y = self._font_ascent
	else
		local lines_h = 0
		for _ in glue.lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = h - self._font_descent
		elseif not valign or valign == 'center' then
			local h1 = h + self._font_ascent - self._font_descent + lines_h
			y = round(h1 / 2)
		else
			assert(false, 'invalid valign "%s"', valign)
		end
		y = y - lines_h
	end

	for s in glue.lines(s) do
		if halign == 'right' then
			local tw = self:_line_extents(s)
			cr:move_to(x - tw, y)
		elseif not halign or halign == 'center' then
			local tw = self:_line_extents(s)
			cr:move_to(x - round(tw / 2), y)
		elseif halign == 'left' then
			cr:move_to(x, y)
		else
			assert(false, 'invalid halign "%s"', halign)
		end
		cr:show_text(s)
		y = y + line_h
	end

	self:pop_cliprect()
end

--selectors ------------------------------------------------------------------

ui.selector = oo.selector(ui.object)

local function noop() end
local function gmatch_tags(s)
	return s and s:gmatch'[^%s]+' or noop
end

function ui.selector:after_init(ui, sel, filter)
	if sel:find'>' then --parents filter
		self.parent_tags = {} --{{tag,...}, ...}
		sel = sel:gsub('%s*([^>%s]+)%s*>', function(s) -- tag > ...
			local tags = collect(gmatch_tags(s))
			push(self.parent_tags, tags)
			return ''
		end)
	end
	self.tags = collect(gmatch_tags(sel)) --tags filter
	assert(next(self.tags))
	self.filter = filter --custom filter
end

--check that all needed_tags are found in tags table as keys
local function has_all_tags(needed_tags, tags)
	for i,tag in ipairs(needed_tags) do
		if not tags[tag] then
			return false
		end
	end
	return true
end

function ui.selector:selects(elem)
	if not has_all_tags(self.tags, elem.tags) then
		return false
	end
	if self.parent_tags then
		local i = #self.parent_tags
		local tags = self.parent_tags[i]
		local elem = elem.parent
		while tags and elem do
			if has_all_tags(tags, elem.tags) then
				if i == 1 then
					return true
				end
				i = i - 1
				tags = self.parent_tags[i]
			end
			elem = elem.parent
		end
		return false
	end
	if self.filter and not self.filter(elem) then
		return false
	end
	return true
end

--stylesheets ----------------------------------------------------------------

ui.stylesheet = oo.stylesheet(ui.object)

function ui:after_init()
	local class_stylesheet = self._stylesheet
	self._stylesheet = self:stylesheet()
	self._stylesheet:add_stylesheet(class_stylesheet)
end

function ui.stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
	self.selectors = {} --{selector1, ...}
end

function ui.stylesheet:add_style(sel, attrs)
	sel.attrs = attrs
	push(self.selectors, sel)
	sel.priority = #self.selectors
	for _,tag in ipairs(sel.tags) do
		local t = attr(self.tags, tag)
		push(t, sel)
	end
end

function ui.stylesheet:add_stylesheet(stylesheet)
	for tag, selectors in pairs(stylesheet.tags) do
		if self.tags[tag] then
			for i,sel in ipairs(selectors) do
				push(self.tags, sel)
			end
		else
			self.tags[tag] = selectors
		end
	end
end

local function cmp_sel(sel1, sel2)
	return sel1.priority < sel2.priority
end

--gather all attribute values from all selectors affecting all tags of elem.
--later selectors affecting a tag take precedence over earlier ones affecting
--that tag. tags are like css classes while elem.tags is like the html class
--attribute which specifies a list of css classes (i.e. tags) to apply.
function ui.stylesheet:_gather_attrs(elem)
	local st = {} --{sel1, ...}
	local checked = {} --{sel -> true}
	for tag in pairs(elem.tags) do
		local selectors = self.tags[tag]
		if selectors then
			for _,sel in ipairs(selectors) do
				if not checked[sel] then
					if sel:selects(elem) then
						push(st, sel)
					end
					checked[sel] = true
				end
			end
		end
	end
	table.sort(st, cmp_sel)
	local t = {} --{attr -> val}
	for _,sel in ipairs(st) do
		update(t, sel.attrs)
	end
	return t
end

local transition_fields = {delay=1, duration=1, ease=1}

local null = {}
local function encode_nil(x) return x == nil and null or x end
local function decode_nil(x) if x == null then return nil end; return x; end

function ui.stylesheet:update_element(elem)
	local attrs = self:_gather_attrs(elem)

	--gather global transition values
	local duration = attrs.transition_duration or 0
	local ease = attrs.transition_ease
	local delay = attrs.transition_delay or 0

	--gather transition-enabled attrs
	local tr
	for attr, val in pairs(attrs) do
		if val == true then
			local tr_attr = attr:match'^transition_(.*)'
			if tr_attr and not transition_fields[tr_attr] then
				tr = tr or {}
				tr[tr_attr] = true
			end
		end
	end

	--add the saved initial values of attributes that were overwritten by this
	--function in the past but are missing from the computed styles this time.
	local rt = elem._revert_attrs
	if rt then
		for attr, val in pairs(rt) do
			if attrs[attr] == nil then
				attrs[attr] = decode_nil(val)
			end
		end
	end

	--save the initial value for an attribute we're about to change for the
	--first time so that later on we can set it back.
	local function save(elem, attr, rt)
		if not rt then
			rt = {}
			elem._revert_attrs = rt
		elseif rt[attr] == nil then --new initial value to save
			local val = elem[attr]
			rt[attr] = encode_nil(val)
		end
		return rt
	end

	--set all attribute values into elem via transition().
	local changed = false
	for attr, val in pairs(attrs) do
		if tr and tr[attr] then
			rt = save(elem, attr, rt)
			local duration = attrs['transition_duration_'..attr] or duration
			local ease = attrs['transition_ease_'..attr] or ease
			local delay = attrs['transition_delay_'..attr] or delay
			elem:transition(attr, val, duration, ease, delay)
			changed = true
		elseif not attr:find'^transition_' then
			rt = save(elem, attr, rt)
			elem:transition(attr, val, 0)
			changed = true
		end
	end

	return changed
end

function ui:style(sel, attrs)
	if type(sel) == 'string' and sel:find(',', 1, true) then
		for sel in sel:gmatch'[^,]+' do
			ui:style(sel, attrs)
		end
	else
		local sel = self:selector(sel)
		self._stylesheet:add_style(sel, attrs)
	end
end

ui._stylesheet = ui:stylesheet()

--attribute types ------------------------------------------------------------

ui._type = {} --{attr -> type}
ui.type = {}  --{patt|f(attr) -> type}

--find an attribute type based on its name
function ui:_attr_type(attr)
	local atype = self._type[attr]
	if not atype then
		for patt, atype1 in pairs(self.type) do
			if (type(patt) == 'string' and attr:find(patt))
				or (type(patt) ~= 'string' and patt(attr))
			then
				atype = atype1
				break
			end
		end
		assert(atype, 'missing attribute type for "%s"', attr)
		self._type[attr] = atype --cache it
	end
	return atype
end

ui.type['_color$'] = 'color'
ui.type['_width$'] = 'number'
ui.type['_height$'] = 'number'
ui.type['^x$'] = 'number'
ui.type['^y$'] = 'number'
ui.type['^w$'] = 'number'
ui.type['^h$'] = 'number'
ui.type['^rotation$'] = 'number'
ui.type['^_cx$'] = 'number'
ui.type['^_cy$'] = 'number'
ui.type['^opacity$'] = 'number'

--transition animations ------------------------------------------------------

ui.transition = oo.transition(ui.object)

ui.transition.interpolate = {} --func(d, x1, x2, xout) -> xout

function ui.transition:after_init(ui, elem, attr, to, duration, ease, delay)

	--timing model
	local start = time.clock() + (delay or 0)
	local ease, way = (ease or 'linear'):match'^([^%s_]+)[%s_]?(.*)'
	if way == '' then way = 'in' end
	local duration = duration or 0

	--animation model
	local atype = ui:_attr_type(attr)
	local interpolate = self.interpolate[atype]
	local from = elem[attr]
	assert(from ~= nil, 'no value for attribute "%s"', attr)
	local v1 = interpolate(1, from, from) --copy for by-ref semantics
	local v2 = interpolate(1, to, to)     --copy for by-ref semantics

	function self:update(clock)
		local t = (clock - start) / duration
		if t < 0 then --not started
			--nothing
		elseif t >= 1 then --finished
			elem[attr] = to
		else --running
			local d = easing.ease(ease, way, t)
			elem[attr] = interpolate(d, v1, v2, elem[attr])
		end
		return t <= 1
	end
end

--interpolators

function ui.transition.interpolate.number(d, x1, x2)
	return lerp(d, 0, 1, tonumber(x1), tonumber(x2))
end

local function rgba(s)
	if type(s) == 'string' then
		return color.string_to_rgba(s)
	else
		return unpack(s)
	end
end

function ui.transition.interpolate.color(d, c1, c2, c)
	local r1, g1, b1, a1 = rgba(c1)
	local r2, g2, b2, a2 = rgba(c2)
	local r = lerp(d, 0, 1, r1, r2)
	local g = lerp(d, 0, 1, g1, g2)
	local b = lerp(d, 0, 1, b1, b2)
	local a = lerp(d, 0, 1, a1, a2)
	if type(c) == 'table' then --by-reference semantics
		c[1], c[2], c[3], c[4] = r, g, b, a
		return c
	else --by-value semantics
		return {r, g, b, a}
	end
end

--element lists --------------------------------------------------------------

ui.element_index = oo.element_index(ui.object)

function ui:after_init()
	self._elements = {}
	self._element_index = self:element_index()
end

function ui.element_index:after_init(ui)
	self.ui = ui
end

function ui.element_index:add_element(elem)
	--TODO
end

function ui.element_index:remove_element(elem)
	--TODO
end

function ui.element_index:find_elements(sel)
	--TODO
	return self.ui:_find_elements(sel, self._elements)
end

ui.element_list = oo.element_list(ui.object)

function ui:_find_elements(sel, elems)
	local res = self.element_list()
	for i,elem in ipairs(elems) do
		if sel:selects(elem) then
			push(res, elem)
		end
	end
	return res
end

function ui.element_list:each(f)
	for i,elem in ipairs(self) do
		local v = f(elem)
		if v ~= nil then return v end
	end
end

function ui.element_list:find(sel)
	return self:_find_elements(sel, self)
end

function ui:find(sel)
	if type(sel) == 'string' then
		sel = self:selector(sel)
	end
	return self._element_index:find_elements(sel)
end

function ui:each(sel, f)
	return self:find(sel):each(f)
end

--elements -------------------------------------------------------------------

ui.element = oo.element(ui.object)

ui.element.visible = true

ui.element.font_family = 'Open Sans'
ui.element.font_weight = 'normal'
ui.element.font_slant = 'normal'
ui.element.text_size = 14
ui.element.text_color = '#fff'
ui.element.line_spacing = 1

--tags & styles

local function add_tags(tags, t)
	for tag in gmatch_tags(tags) do
		t[tag] = true
	end
end

function ui.element:after_init(ui, t)
	self.ui = ui

	local class_tags = self.tags
	local tags = {['*'] = true}
	add_tags(class_tags, tags)
	tags[self.classname] = true
	if self.id then
		tags[self.id] = true
	end
	add_tags(t.tags, tags)
	self.tags = tags
	self._instance_attrs = t --TODO: how to integrate this with css?
	self:update_styles()

	update(self, t)
	self.tags = tags
end

function ui.element:_addtags(s)
	self.tags = self.tags and self.tags .. ' ' .. s or s
end

function ui.element:settags(s)
	for op, tag in s:gmatch'([-+~]?)([^%s]+)' do
		if op == '' or op == '+' then
			self.tags[tag] = true
		elseif op == '-' then
			self.tags[tag] = false
		elseif op == '~' then
			self.tags[tag] = not self.tags[tag]
		end
	end
	if self:update_styles() then
		self:invalidate()
	end
end

function ui.element:update_styles()
	return self.ui._stylesheet:update_element(self)
end

--animated attribute transitions

function ui.element:transition(attr, val, duration, ease, delay)
	if duration <= 0 then
		if self._transitions then
			self._transitions[attr] = nil --remove transition on attr if any
		end
		self[attr] = val --set attr directly
	else --set attr with transition
		self._transitions = self._transitions or {}
		self._transitions[attr] =
			self.ui:transition(self, attr, val, duration, ease, delay)
	end
end

function ui.element:draw()
	--update transitioning attributes
	local a = self._transitions
	if not a or not next(a) then return end
	local clock = self:frame_clock()
	local invalidate
	for attr, transition in pairs(a) do
		if transition:update(clock) then
			invalidate = true
		else
			a[attr] = nil --finished, remove it
		end
	end
	if invalidate then
		self:invalidate(true)
	end
end

--windows --------------------------------------------------------------------

ui.window = oo.window(ui.element)

ui.window.background_color = '#000'

function ui.window:after_init(ui, t)
	self.dr = ui:draw()
	local win = self.window

	self.x, self.y = 0, 0
	self.w, self.h = win:client_size()

	win:on('mousemove.ui', function(win, x, y)
		self:_mousemove(x, y)
	end)
	win:on('mouseenter.ui', function(win, x, y)
		self:_mouseenter(x, y)
	end)
	win:on('mouseleave.ui', function(win)
		self:_mouseleave()
	end)
	win:on('mousedown.ui', function(win, button, x, y)
		self:_mousedown(button, x, y)
	end)
	win:on('mouseup.ui', function(win, button, x, y)
		self:_mouseup(button, x, y)
	end)
	win:on('repaint.ui', function(win)
		self._frame_clock = time.clock()
		self.dr.cr = win:bitmap():cairo()
		self:draw()
	end)
	win:on('client_resized.ui', function(win, cw, ch)
		self.w = cw
		self.h = ch
	end)
	win:on('closed.ui', function()
		self:free()
	end)

	self._layers = {}

	self.hot_widget = false
	self.active_widget = false
end

function ui.window:free()
	self.dr:free()
	self.window:off'.ui'
	self.window = nil
end

--layer management

function ui.window:sort_layers()
	table.sort(self._layers, function(a, b)
		return a.z_order < b.z_order
	end)
end

function ui.window:add_layer(layer)
	push(self._layers, layer)
	self:sort_layers()
end

function ui.window:remove_layer(layer)
	local i = indexof(layer, self._layers)
	if i then pop(self._layers, i) end
end

--mouse events routing to layers. hit-testing is based on layer's `z_order`.
--mouseenter/mouseleave events are based on `hot_widget` and `active_widget`.
--mouse events are given relative to widget's (x, y).

function ui.window:hit_test_layer(x, y)
	for i = #self._layers, 1, -1 do
		local layer = self._layers[i]
		if layer:hit_test(x, y) then
			return layer
		end
	end
end

function ui.window:_set_hot_widget(widget, mx, my)
	if self.hot_widget == widget then
		return
	end
	if self.hot_widget then
		self.hot_widget:fire'mouseleave'
	end
	if widget then
		--the hot widget is still the old widget when entering the new widget
		widget:_mouseenter(mx, my)
	end
	self.hot_widget = widget
end

function ui.window:_set_hot_window(hot)
	self.hot = hot
	self:settags(hot and 'hot' or '-hot')
end

function ui.window:_mousemove(mx, my)
	if self.mouse_x == mx and self.mouse_y == my then
		return
	end
	self.mouse_x = mx
	self.mouse_y = my
	self:fire('mousemove', mx, my)
	local widget = self.active_widget
	if widget then
		widget:_mousemove(mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test_layer(mx, my)
		self:_set_hot_widget(widget, mx, my)
		self:_set_hot_window(not widget)
		if widget then
			widget:_mousemove(mx, my)
		end
	end
end

function ui.window:_mouseenter(mx, my)
	self:fire('mouseenter', mx, my)
	self:_mousemove(mx, my)
end

function ui.window:_mouseleave()
	self.mouse_x = false
	self.mouse_y = false
	self:fire'mouseleave'
	local widget = self.active_widget
	if widget then
		widget:_mouseleave()
	end
	self:_set_hot_widget(false)
	self:_set_hot_window(false)
end


function ui.window:_mousedown(button, mx, my)
	self.mouse_x = mx
	self.mouse_y = my
	self:fire('mousedown', button, mx, my)
	local widget = self.active_widget
	if widget then
		widget:_mousedown(button, mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test_layer(mx, my)
		self:_set_hot_widget(widget, mx, my)
		self:_set_hot_window(not widget)
		if widget then
			widget:_mousedown(button, mx, my)
		end
	end
end

function ui.window:_mouseup(button, mx, my)
	self.mouse_x = mx
	self.mouse_y = my
	self:fire('mouseup', button, mx, my)
	local widget = self.active_widget
	if widget then
		widget:_mouseup(button, mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test_layer(mx, my)
		self:_set_hot_widget(widget, mx, my)
		self:_set_hot_window(not widget)
		if widget then
			widget:_mouseup(button, mx, my)
		end
	end
end

--rendering layers

function ui.window:after_draw()
	if not self.visible then return end
	self.dr:rect(self.x, self.y, self.w, self.h, self.background_color)
	for i = 1, #self._layers do
		local layer = self._layers[i]
		layer:draw()
	end
end

--widget-like

function ui.window:invalidate(for_animation)
	if not self.visible then return end
	self.window:invalidate()
end

function ui.window:rect()
	return self.x, self.y, self.w, self.h
end

function ui.window:pos()
	return self.x, self.y
end

function ui.window:size()
	return self.w, self.h
end

function ui.window:frame_clock()
	return self._frame_clock
end

--layers ---------------------------------------------------------------------

ui.layer = oo.layer(ui.element)

ui.layer.clipping = true
ui.layer.border_width = 0
ui.layer.opacity = 1
ui.layer._z_order = 0
ui.layer._rotation = 0
ui.layer._rotation_cx = 0
ui.layer._rotation_cy = 0
ui.layer._x = 0
ui.layer._y = 0

function ui.layer:after_init(ui, t)
	if self.parent then return end
	self.window:add_layer(self)
	self._added = true
	self._matrix = cairo.matrix()
	self._inv_matrix = cairo.matrix()
	self._matrix_valid = false
end

local function getset(attr)
	local uattr = '_'..attr
	ui.layer['get'..uattr] = function(self)
		return self[uattr]
	end
	ui.layer['set'..uattr] = function(self, val)
		self[uattr] = val
		self._matrix_valid = false
		--self:invalidate() --TODO: call invalidate on basically all field changes
	end
	assert(ui.layer.__getters[attr])
end
getset'x'
getset'y'
getset'w'
getset'h'
getset'rotation_cx'
getset'rotation_cy'
getset'rotation'

function ui.layer:get_z_order()
	return self._z_order
end

function ui.layer:set_z_order(z_order)
	if self.parent then return end
	self._z_order = z_order
	if self._added then
		self.window:sort_layers()
	end
end

function ui.layer:_get_matrix()
	if not self._matrix_valid then
		local m, im = self._matrix, self._inv_matrix
		m:reset():translate(self.x, self.y)
		m:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		im:reset(m):invert()
		self._matrix_valid = true
	end
	return self._matrix
end

function ui.layer:_get_inv_matrix()
	self:_get_matrix()
	return self._inv_matrix
end

function ui.layer:pos()
	return self.x, self.y
end

function ui.layer:size()
	return self.w, self.h
end

function ui.layer:rect()
	return self.x, self.y, self.w, self.h
end

function ui.layer:to_screen(x, y)
	return self:_get_matrix():point(x, y)
end

function ui.layer:from_screen(x, y)
	return self:_get_inv_matrix():point(x, y)
end

function ui.layer:mouse_pos()
	if not self.window.mouse_x then
		return false, false
	end
	return self:from_screen(self.window.mouse_x, self.window.mouse_y)
end

function ui.layer:get_mouse_x()
	local x, y = self:mouse_pos()
	return x
end

function ui.layer:get_mouse_y()
	local x, y = self:mouse_pos()
	return y
end

function ui.layer:hit_test(x, y)
	local x, y = self:from_screen(x, y)
	return box2d.hit(x, y, 0, 0, self.w, self.h)
end

function ui.layer:hit(x, y, w, h)
	local mx, my = self:mouse_pos()
	return box2d.hit(mx, my, x, y, w, h)
end

function ui.layer:_mouseenter(mx, my)
	local mx, my = self:from_screen(mx, my)
	self:fire('mouseenter', mx, my)
end

function ui.layer:_mouseleave()
	self:fire'mouseleave'
end

function ui.layer:_mousemove(mx, my)
	local mx, my = self:from_screen(mx, my)
	self:fire('mousemove', mx, my)
end

function ui.layer:_mousedown(button, mx, my)
	local mx, my = self:from_screen(mx, my)
	self:fire('mousedown', button, mx, my)
end

function ui.layer:_mouseup(button, mx, my)
	local mx, my = self:from_screen(mx, my)
	self:fire('mouseup', button, mx, my)
end

function ui.layer:draw_inside() end --stub

function ui.layer:after_draw()
	if not self.visible then return end
	if self.opacity <= 0 then return end
	local dr = self.window.dr

	local cr = dr.cr
	cr:save()
	cr:matrix(self:_get_matrix())
	if self.clipping then
		cr:rectangle(box2d.offset(self.border_width, 0, 0, self.w, self.h))
		cr:clip()
	end

	local opacity = self.opacity
	local compose = opacity < 1
	if compose then
		cr:push_group()
	end

	if self.background_color then
		dr:rect(0, 0, self.w, self.h, self.background_color)
	end

	if self.border_color then
		dr:border(0, 0, self.w, self.h, self.border_color, self.border_width)
	end

	self:draw_inside()

	if compose then
		cr:pop_group_to_source()
		cr:paint_with_alpha(opacity)
	end

	cr:restore()
end

--the `hot` property and tag which is automatically set

function ui.layer:get_hot()
	return self.window.hot_widget == self
end

function ui.layer:mouseenter()
	if not self.window.active_widget then
		self:settags'hot'
	end
end

function ui.layer:mouseleave()
	self:settags'-hot'
end

--the `active` property and tag which the widget must set manually

function ui.layer:get_active()
	return self.window.active_widget == self
end

function ui.layer:set_active(active)
	if self.active == active then return end
	local active_widget = self.window.active_widget
	if active_widget then
		active_widget:settags'-active'
		self.window.active_widget = false
	end
	if active then
		self.window.active_widget = self
		self:settags'active'
	end
end

--animations management

function ui.layer:frame_clock()
	return self.window:frame_clock()
end

function ui.layer:invalidate(for_animation)
	if not self.visible then return end
	self.window:invalidate(for_animation)
end

--buttons --------------------------------------------------------------------

ui.button = oo.button(ui.layer)

ui.button.background_color = '#444'
ui.button.border_color = '#888'
ui.button.border_width = 1

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = 0.5,
	transition_ease = 'expo out',
})

ui:style('button hot', {
	background_color = '#ccc',
	border_color = '#ccc',
	text_color = '#000',
})

ui:style('button active', {
	background_color = '#fff',
	border_color = '#fff',
	text_color = '#000',
	transition_duration = 0.2,
})

function ui.window:button(t)
	t.window = self
	return self.ui:button(t)
end

function ui.button:mousedown(button, x, y)
	if button == 'left' then
		self.active = true
	end
end

function ui.button:mouseup(button, x, y)
	if button == 'left' then
		self.active = false
	end
end

function ui.button:draw_inside()
	local dr = self.window.dr
	if self.text then
		dr:textbox(0, 0, self.w, self.h, self.text,
			self.font_family, self.font_weight, self.font_slant, self.text_size,
			self.line_spacing, self.text_color, 'center', 'center')
	end
end

--scrollbars -----------------------------------------------------------------

ui.scrollbar = oo.scrollbar(ui.layer)

ui.scrollbar:_addtags'scrollbar'

ui.scrollbar.step = 1
ui.scrollbar.thickness = 20
ui.scrollbar.min_width = 0
ui.scrollbar.autohide = true
ui.scrollbar.background_color = '#222'
ui.scrollbar.grabber_background_color = '#444'
ui.scrollbar.opacity = 0

ui:style('scrollbar', {
	transition_background_color = true,
	transition_duration = 0.5,
	transition_ease = 'expo out',

	transition_opacity = true,
	transition_delay_opacity = 0.5,
	transition_duration_opacity = 1,
})

ui:style('scrollbar near', {
	opacity = 1,
	transition_opacity = true,
	transition_duration_opacity = 0.5,
	transition_delay_opacity = 0,
})

ui:style('scrollbar hot', {
	grabber_background_color = '#ccc',
})

ui:style('scrollbar active', {
	grabber_background_color = '#fff',
	transition_duration = 0.2,
})

function ui.scrollbar:set_thickness(thickness)
	if self.vertical then
		self.w = self.w or thickness
	else
		self.h = self.h or thickness
	end
end

local function client_offset_round(i, step)
	return i - i % step
end

local function client_offset(bx, w, bw, size, step)
	return client_offset_round(bx / (w - bw) * (size - w), step)
end

local function client_offset_clamp(i, size, w, step)
	return client_offset_round(clamp(i, 0, math.max(size - w, 0)), step)
end

local function bar_size(w, size, minw)
	return clamp(w^2 / size, minw, w)
end

local function bar_offset(w, size, i, bw)
	return i * (w - bw) / (size - w)
end

local function bar_offset_clamp(bx, w, bw)
	return clamp(bx, 0, w - bw)
end

local function bar_segment(w, size, i, minw)
	local bw = bar_size(w, size, minw)
	local bx = bar_offset(w, size, i, bw)
	local bx = bar_offset_clamp(bx, w, bw)
	return bx, bw
end

function ui.scrollbar:hit_test_near(mx, my)
	return 1 - clamp(math.abs(self.vertical and mx or my), 0, 100) / 100 > 0
end

function ui.scrollbar:after_init(ui, t)
	self.offset = client_offset_clamp(self.offset or 0, self.size,
		self.vertical and self.h or self.w, self.step)

	self.window:on('mousemove.'..tostring(self), function(win, mx, my)
		local mx, my = self:from_screen(mx, my)
		local near = self:hit_test_near(mx, my)
		if near and not self._to1 then
			self._to1 = true
			self._to0 = false
			self:settags'near'
		elseif not near and not self._to0 then
			self._to0 = true
			self._to1 = false
			self:settags'-near'
		end
		self:invalidate()
	end)

	self.window:on('mouseleave.'..tostring(self), function(win, mx, my)
		if not self._to0 then
			self._to0 = true
			self._to1 = false
			self:settags'-near'
		end
	end)
end

function ui.scrollbar:before_free()
	self.window:off('.'..tostring(self))
end

function ui.scrollbar:grabbar_rect()
	local bx, by, bw, bh
	if self.vertical then
		by, bh = bar_segment(self.h, self.size, self.offset, self.min_width)
		bx, bw = 0, self.w
	else
		bx, bw = bar_segment(self.w, self.size, self.offset, self.min_width)
		by, bh = 0, self.h
	end
	return bx, by, bw, bh
end

function ui.scrollbar:after_mousedown(button, mx, my)
	if button == 'left' and not self._grab then
		local bx, by, bw, bh = self:grabbar_rect()
		if self:hit(bx, by, bw, bh) then
			self._grab = self.vertical and my - by or mx - bx
			self.active = true
		end
	end
end

function ui.scrollbar:after_mouseup(button, mx, my)
	if button == 'left' and self._grab then
		self._grab = false
		self.active = false
	end
end

function ui.scrollbar:after_mousemove(mx, my)
	if self._grab then
		local offset = self.offset
		local bx, by, bw, bh = self:grabbar_rect()
		if self.vertical then
			local by = bar_offset_clamp(my - self._grab, self.h, bh)
			self.offset = client_offset(by, self.h, bh, self.size, self.step)
		else
			local bx = bar_offset_clamp(mx - self._grab, self.w, bw)
			self.offset = client_offset(bx, self.w, bw, self.size, self.step)
		end
		if self.offset ~= offset then
			self:fire('changed', self.offset, offset)
			self:invalidate()
		end
	end
end

function ui.scrollbar:draw_inside()
	local dr = self.window.dr
	local bx, by, bw, bh = self:grabbar_rect()
	--	if bw < w or bh < h then
	dr:rect(bx, by, bw, bh, self.grabber_background_color)
end

ui.hscrollbar = ui.scrollbar
ui.vscrollbar = oo.vscrollbar(oo.scrollbar)
ui.vscrollbar.vertical = true

function ui.window:hscrollbar(t)
	t.window = self
	return self.ui:hscrollbar(t)
end

function ui.window:vscrollbar(t)
	t.window = self
	return self.ui:vscrollbar(t)
end

--scrollbox ------------------------------------------------------------------

ui.scrollbox = oo.scrollbox(ui.layer)

ui:style('scrollbox', {
	vscroll = 'always',
	hscroll = 'always',
	scroll_width = 20,
	page_size = 120,
})

function ui.scrollbox:after_init(ui, t)
	self.scroll_width = t.scroll_width or self.scroll_width
	self.vscroll_width = t.vscroll_width or self.vscroll_width or self.scroll_width
	self.hscroll_width = t.hscroll_width or self.hscroll_width or self.scroll_width
	self.vscroll_step = t.vscroll_step or self.vscroll_step
	self.hscroll_step = t.hscroll_step or self.hscroll_step
	self.page_size = t.page_size or self.page_size

	local need_vscroll = vscroll == 'always'
		or (vscroll == 'auto' and ch > h -
			((hscroll == 'always' or hscroll == 'auto' and cw > w - vscroll_w) and hscroll_h or 0))
	local need_hscroll = hscroll == 'always' or
		(hscroll == 'auto' and cw > w - (need_vscroll and vscroll_w or 0))

	w = need_vscroll and w - vscroll_w or w
	h = need_hscroll and h - hscroll_h or h

	if self.wheel_delta ~= 0 and not self.active and self:hotbox(x, y, w, h) then
		cy = cy + self.wheel_delta * page_size
	end

	--drawing
	if need_vscroll then
		cy = -self:vscrollbar{id = id .. '_vscrollbar', x = x + w, y = y, w = vscroll_w, h = h,
										size = ch, i = -cy, step = vscroll_step}
	end
	if need_hscroll then
		cx = -self:hscrollbar{id = id .. '_hscrollbar', x = x, y = y + h, w = w, h = hscroll_h,
										size = cw, i = -cx, step = hscroll_step}
	end

	return
		cx, cy,     --client area coordinates, relative to the clipping rectangle
		x, y, w, h  --clipping rectangle, in absolute coordinates
end



if not ... then

jit.off(true, true)

local nw = require'nw'
local app = nw:app()
local win = app:window{x = 940, y = 400, w = 800, h = 400}
local ui = ui()

ui:style('*', {
	custom_all = 11,
})

ui:style('button', {
	custom_field = 42,
})

ui:style('button b1', {
	custom_and = 13,
})

ui:style('b1', {
	custom_and = 16, --comes later: overwrite (no specificity)
})

ui:style('button', {
	custom_and = 22, --comes later: overwrite (no specificity)
})

ui:style('p1 > p2 > b1', {
	custom_parent = 54, --comes later: overwrite (no specificity)
})

local win = ui:window{window = win}

local p1 = ui:element{name = 'p1', tags = 'p1'}
local p2 = ui:element{name = 'p2', tags = 'p2', parent = p1}
local b1 = win:button{parent = p2, name = 'b1', tags = 'b1', ctl = ctl, x = 10, y = 10, w = 100, h = 26}
local b2 = win:button{parent = p2, name = 'b2', tags = 'b2', ctl = ctl, x = 20, y = 20, w = 100, h = 26}
local sel = ui:selector('p1 > p2 > b1')
assert(sel:selects(b1) == true)
print('b1.custom_all', b1.custom_all)
print('b2.custom_all', b2.custom_all)
print('b1.custom_field', b1.custom_field)
print('b1.custom_and', b1.custom_and)
print('b2.custom_and', b2.custom_and)
--print('b2.custom_and', b2.custom_and)

--ui:style('button', {h = 26})

local b1 = win:button{name = 'b1', tags = 'b1', text = 'B1', ctl = ctl, x = 10, y = 10, w = 100, h = 26}
local b2 = win:button{name = 'b2', tags = 'b2', text = 'B2', ctl = ctl, x = 20, y = 50, w = 100, h = 26}
b1.z_order = 2

ui:style('vscrollbar', {
	rotation = 180 + 30,
	rotation_cx = 10,
	rotation_cy = 100,
	transition_rotation = true,
	transition_duration = 1,
})

local s1 = win:hscrollbar{id = 's1', x = 10, y = 100, w = 200, h = 20, size = 1000}
local s2 = win:vscrollbar{id = 's2', x = 250, y = 10, w = 20, h = 200, size = 500}

ui:style('window hot', {background_color = '#080808'})

function s1:changed(i)
	--s2.rotation = i
	--s2.opacity = lerp(i, 0, 1000, 0, 1)
	s2:invalidate()
end

app:run()

ui:free()

end

return ui
