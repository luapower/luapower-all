
--extensible UI toolkit with layouts, styles and animations.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'ui_demo'; return end

local oo = require'oo'
local glue = require'glue'
local tuple = require'tuple'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local amoeba = require'amoeba'
local time = require'time'
local gfonts = require'gfonts'
local freetype = require'freetype'
local cairo = require'cairo'
local libjpeg = require'libjpeg'
local fs = require'fs'

local push = table.insert
local pop = table.remove

local indexof = glue.indexof
local update = glue.update
local merge = glue.merge
local attr = glue.attr
local lerp = glue.lerp
local clamp = glue.clamp
local assert = glue.assert
local collect = glue.collect
local sortedpairs = glue.sortedpairs
local memoize = glue.memoize

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local function round(x)
	return math.floor(x + .5)
end

local function args4(s, convert) --parse a string of 4 non-space args
	local a1, a2, a3, a4
	if type(s) == 'string' then
		a1, a2, a3, a4 = s:match'([^%s]+)%s+([^%s]+)([^%s]+)%s+([^%s]+)'
	end
	if not a1 then
		a1, a2, a3, a4 = s, s, s, s
	end
	if convert then
		return convert(a1), convert(a2), convert(a3), convert(a4)
	else
		return a1, a2, a3, a4
	end
end

--object system --------------------------------------------------------------

local object = oo.object()

--speed up class field lookup by converting subclassing to static
--inheritance. note that runtime patching of non-final classes doesn't work
--anymore (extending classes still works but it's less useful).
function object:override_subclass(inherited, ...)
	return inherited(self, ...):inherit(self)
end

--speed up virtual property lookup without detaching instances completely
--which would make instances too fat. patching of getters and setters through
--instances is not allowed anymore because this will patch the class instead!
function object:before_init()
	self.__setters = self.__setters
	self.__getters = self.__getters
end

--generic method memoizer
function object:memoize(method_name)
	function self:after_init()
		local method = self[method_name]
		local memfunc = memoize(function(...)
			return method(self, ...)
		end)
		self[method_name] = function(self, ...)
			return memfunc(...)
		end
	end
end

--module object --------------------------------------------------------------

local ui = oo.ui(object)
ui.object = object

function ui:error(msg, ...)
	msg = string.format(msg, ...)
	io.stderr:write(msg)
	io.stderr:write'\n'
end

function ui:check(ret, ...)
	if ret then return ret end
	self:error(...)
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

local transition_fields = {delay=1, duration=1, ease=1, speed=1}

local nilkey = {}
local function encode_nil(x) return x == nil and nilkey or x end
local function decode_nil(x) if x == nilkey then return nil end; return x; end

function ui.stylesheet:update_element(elem)
	local attrs = self:_gather_attrs(elem)

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
		end
		if rt[attr] == nil then --new initial value to save
			local val = elem[attr]
			rt[attr] = encode_nil(val)
		end
		return rt
	end

	--gather global transition values
	local duration = attrs.transition_duration or 0
	local ease = attrs.transition_ease
	local delay = attrs.transition_delay or 0
	local speed = attrs.transition_speed or 1

	--set all attribute values into elem via transition().
	local changed = false
	for attr, val in pairs(attrs) do
		if tr and tr[attr] then
			rt = save(elem, attr, rt)
			local duration = attrs['transition_duration_'..attr] or duration
			local ease = attrs['transition_ease_'..attr] or ease
			local delay = attrs['transition_delay_'..attr] or delay
			local speed = attrs['transition_speed_'..attr] or speed
			elem:transition(attr, val, duration / speed, ease, delay)
			changed = true
		elseif not attr:find'^transition_' then
			rt = save(elem, attr, rt)
			elem:transition(attr, val, 0)
			changed = true
		end
	end

	return changed
end

function ui.stylesheet:update_style(style)
	for _,elem in ipairs(self._elements) do
		--TODO:
	end
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
	for patt, atype in pairs(self.type) do
		if (type(patt) == 'string' and attr:find(patt))
			or (type(patt) ~= 'string' and patt(attr))
		then
			return atype
		end
	end
	return 'number'
end
ui:memoize'_attr_type'

ui.type['_color$'] = 'color'
ui.type['_color_'] = 'color'
ui.type['_colors$'] = 'gradient_colors'

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
	elem[attr] = v1 --set to its copy to avoid overwriting the original

	function self:update(clock)
		local t = (clock - start) / duration
		if t < 0 then --not started
			--nothing
		elseif t >= 1 then --finished, set to actual final value
			elem[attr] = to
		else --running, set to interpolated value
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

function ui.transition.interpolate.gradient_colors(d, t1, t2, t)
	t = t or {}
	local offset1, offset2 = 0, 0
	for i,arg1 in ipairs(t1) do
		local arg2 = t2[i]
		local atype = type(arg1) == 'number' and 'number' or 'color'
		t[i] = ui.transition.interpolate[atype](d, arg1, arg2, t[i])
	end
	return t
end

--element lists --------------------------------------------------------------

ui.element_index = oo.element_index(ui.object)

function ui:after_init()
	self._elements = {}
	self._element_index = self:element_index()
end

function ui:before_free()
	while #self._elements > 0 do
		self._elements[#self._elements]:free()
	end
end

function ui:_add_element(elem)
	push(self._elements, elem)
	self._element_index:add_element(elem)
end

function ui:_remove_element(elem)
	popval(self._elements, elem)
	self._element_index:remove_element(elem)
end

function ui:_find_elements(sel, elems)
	local elems = elems or self._elements
	local res = self.element_list()
	for i,elem in ipairs(elems) do
		if sel:selects(elem) then
			push(res, elem)
		end
	end
	return res
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
	return self.ui:_find_elements(sel)
end

ui.element_list = oo.element_list(ui.object)

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

	self.ui:_add_element(self)

	local class_tags = self.tags
	local tags = {['*'] = true}
	add_tags(class_tags, tags)
	tags[self.classname] = true
	add_tags(t.tags, tags)
	self.tags = tags
	--update elements in lexicographic order so that eg. `border_width` comes
	--before `border_width_left`.
	for k,v in sortedpairs(t) do
		self[k] = v
	end
	self.tags = tags
	if self.id then
		tags[self.id] = true
	end
	self:update_styles()
end

function ui.element:before_free()
	self.ui:_remove_element(self)
	self.ui = false
end

function ui.element:_addtags(s)
	self.tags = self.tags and self.tags .. ' ' .. s or s
end

function ui.element:_subtag(tag)
	tag = self.classname..'_'..tag
	return self.id and self.id..'.'..tag or tag
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
	if not duration or duration <= 0 then
		if self._transitions then
			self._transitions[attr] = nil --remove existing transition on attr
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

--direct manipulation interface

--TODO: function ui.element


--windows --------------------------------------------------------------------

ui.window = oo.window(ui.element)

ui:style('window_layer', {
	--screen-wiping options that work with transparent windows
	background_color = '#0000',
	background_operator = 'source',
})

function ui.window:after_init(ui, t)

	local win = self.native_window

	self.x, self.y, self.w, self.h = self.native_window:client_rect()

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false

	local function setcontext()
		self._frame_clock = time.clock()
		self.cr = win:bitmap():cairo()
	end

	win:on('mousemove.ui', function(win, x, y)
		setcontext()
		self:_mousemove(x, y)
	end)
	win:on('mouseenter.ui', function(win, x, y)
		setcontext()
		self:_mouseenter(x, y)
	end)
	win:on('mouseleave.ui', function(win)
		setcontext()
		self:_mouseleave()
	end)
	win:on('mousedown.ui', function(win, button, x, y)
		setcontext()
		self:_mousedown(button, x, y)
	end)
	win:on('mouseup.ui', function(win, button, x, y)
		setcontext()
		self:_mouseup(button, x, y)
	end)
	win:on('repaint.ui', function(win)
		setcontext()
		self:draw()
	end)
	win:on('client_rect_changed.ui', function(win, cx, cy, cw, ch)
		if not cx then return end --hidden or minimized
		self.x = cx
		self.y = cy
		self.w = cw
		self.h = ch
		self.layer.w = cw
		self.layer.h = ch
	end)
	win:on('closed.ui', function()
		self:free()
	end)

	self.hot_widget = false
	self.active_widget = false

	self.layer = self.layer_class(self.ui, merge({
		id = self:_subtag'layer', x = 0, y = 0, w = self.w, h = self.h,
		parent = self, content_clip = false,
	}, self.layer))
end

function ui.window:before_free()
	self.native_window:off'.ui'
	self.hot_widget = false
	self.active_widget = false
	self.layer:free()
	self.native_window = false
end

--`hot` and `active` widget logic and mouse events routing

function ui.window:_set_hot_widget(widget, mx, my, area)
	if self.hot_widget == widget then
		return
	end
	if self.hot_widget then
		self.hot_widget:_mouseleave()
	end
	if widget then
		--the hot widget is still the old widget when entering the new widget
		widget:_mouseenter(mx, my, area)
	end
	self.hot_widget = widget
end

function ui.window:_mousemove(mx, my, force)
	if not force and self.mouse_x == mx and self.mouse_y == my then
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
		local widget, area = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my, area)
		if widget then
			widget:_mousemove(mx, my, area)
		end
	end
end

function ui.window:_mouseenter(mx, my)
	self:fire('mouseenter', mx, my)
	self:_mousemove(mx, my, true)
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
		local widget, area = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my, area)
		if widget then
			widget:_mousedown(button, mx, my, area)
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
		local widget, area = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my, area)
		if widget then
			widget:_mouseup(button, mx, my, area)
		end
	end
end

function ui.window:hit_test(x, y)
	return self.layer:hit_test(x, y)
end

--rendering

function ui.window:after_draw()
	if not self.visible or self.opacity == 0 then return end
	self.cr:save()
	self.cr:new_path()
	self.layer:draw()
	self.cr:restore()
end

--parent interface

function ui.window:_add_layer(layer)
	if not self.layer then return end
	self.layer:_add_layer(layer)
end
function ui.window:_remove_layer(layer)
	if layer == self.layer then return end
	self.layer:_remove_layer(layer)
end

local function pass_xy(self, x, y)
	return x, y
end
ui.window.from_window = pass_xy
ui.window.to_window   = pass_xy

function ui.window:mouse_pos()
	return self.mouse_x, self.mouse_y
end

--window interface; also element interface

function ui.window:invalidate(for_animation)
	self.native_window:invalidate()
end

function ui.window:frame_clock()
	return self._frame_clock
end

--sugar & utils

function ui.window:rect() return 0, 0, self.w, self.h end
function ui.window:size() return self.w, self.h end

--drawing helpers ------------------------------------------------------------

function ui:_color(s)
	return {color.string_to_rgba(s)}
end
ui:memoize'_color'

function ui:color(c)
	return unpack(type(c) == 'string' and self:_color(c) or c)
end

function ui:_add_color_stops(g, ...)
	local offset = 0
	for i=1,select('#', ...) do
		local arg = select(i, ...)
		if type(arg) == 'number' then
			offset = arg
		else
			g:add_color_stop(offset, self:color(arg))
		end
	end
	return g
end

function ui:linear_gradient(x1, y1, x2, y2, ...)
	local g = cairo.linear_gradient(x1, y1, x2, y2)
	return self:_add_color_stops(g, ...)
end

function ui:radial_gradient(cx1, cy1, r1, cx2, cy2, r2, ...)
	local g = cairo.radial_gradient(cx1, cy1, r1, cx2, cy2, r2)
	return self:_add_color_stops(g, ...)
end

function ui:image(file)
	local ext = file:match'%.([^%.]+)$'
	if ext == 'jpg' or ext == 'jpeg' then
		local f, err = fs.open(file)
		if not f then
			self:error('error loading "%s": %s', file, err)
			return
		end
		local bread = f:buffered_read()
		local function read(buf, sz)
			return self:check(bread(buf, sz))
		end
		local img = self:check(libjpeg.open({read = read}))
		if not img then return end
		local bmp = self:check(img:load{accept = {bgra8 = true}})
		if not bmp then return end
		img:free()
		local sr = cairo.image_surface(bmp) --bmp is Lua-pinned to sr
		local patt = cairo.surface_pattern(sr) --sr is cairo-pinned to patt
		return {patt = patt, sr = sr}
	end
end
ui:memoize'image'

--fonts and text

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

function ui.window:before_free()
	if self.cr then
		self.cr:font_face(cairo.NULL)
	end
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
function ui.window:setfont(family, weight, slant, size)
	local face = self.ui:_font_face(family, weight, slant)
	self.cr:font_face(face.cr_face)
	self.cr:font_size(size)
	local ext = self.cr:font_extents()
	self._font_height = ext.height
	self._font_descent = ext.descent
	self._font_ascent = ext.ascent
end

--multi-line self-aligned and box-aligned text

function ui.window:line_extents(s)
	local ext = self.cr:text_extents(s)
	return ext.width, ext.height, ext.y_bearing
end

function ui.window:textbox(x, y, w, h, s,
	font_family, font_weight, font_slant, text_size, line_spacing, text_color,
	halign, valign)

	self:setfont(font_family, font_weight, font_slant, text_size)
	self.cr:rgba(self.ui:color(text_color))

	self.cr:save()
	self.cr:rectangle(x, y, w, h)
	self.cr:clip()

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
			local tw = self:line_extents(s)
			cr:move_to(x - tw, y)
		elseif not halign or halign == 'center' then
			local tw = self:line_extents(s)
			cr:move_to(x - round(tw / 2), y)
		elseif halign == 'left' then
			cr:move_to(x, y)
		else
			assert(false, 'invalid halign "%s"', halign)
		end
		cr:show_text(s)
		y = y + line_h
	end

	self.cr:restore()
end

--layers ---------------------------------------------------------------------

ui.layer = oo.layer(ui.element)
ui.window.layer_class = ui.layer

function ui.layer:set_padding(s)
	self.padding_left, self.padding_top, self.padding_right,
		self.padding_bottom = args4(s, tonumber)
end

function ui.layer:set_border_color(s)
	self.border_color_left, self.border_color_right,
		self.border_color_top, self.border_color_bottom = args4(s)
end

function ui.layer:set_border_width(s)
	self.border_width_left, self.border_width_right,
		self.border_width_top, self.border_width_bottom = args4(s, tonumber)
end

function ui.layer:set_border_radius(s)
	self.border_radius_top_left, self.border_radius_top_right,
		self.border_radius_bottom_right, self.border_radius_bottom_left =
			args4(s, tonumber)
end

function ui.layer:set_scale(scale)
	self.scale_x = scale
	self.scale_y = scale
end

function ui.layer:set_background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

ui.layer.x = 0
ui.layer.y = 0
ui.layer.rotation = 0
ui.layer.rotation_cx = 0
ui.layer.rotation_cy = 0
ui.layer.scale = 1
ui.layer.scale_cx = 0
ui.layer.scale_cy = 0

ui.layer._z_order = 0

ui.layer.opacity = 1

ui.layer.content_clip = true --'padding'/true, 'background', false

ui.layer.padding = 0

ui.layer.background_type = 'color'
--all backgrounds
ui.layer.background_x = 0
ui.layer.background_y = 0
ui.layer.background_rotation = 0
ui.layer.background_rotation_cx = 0
ui.layer.background_rotation_cy = 0
ui.layer.background_scale = 1
ui.layer.background_scale_cx = 0
ui.layer.background_scale_cy = 0
--soldi color backgrounds
ui.layer.background_color = nil --no background
--gradient backgrounds
ui.layer.background_colors = {} --{[offset1], color1, ...}
--linear gradient backgrounds
ui.layer.background_x1 = 0
ui.layer.background_y1 = 0
ui.layer.background_x2 = 0
ui.layer.background_y2 = 0
--radial gradient backgrounds
ui.layer.background_cx1 = 0
ui.layer.background_cy1 = 0
ui.layer.background_r1 = 0
ui.layer.background_cx2 = 0
ui.layer.background_cy2 = 0
ui.layer.background_r2 = 0
--image backgrounds
ui.layer.background_image = nil

ui.layer.background_operator = 'over'
-- overlapping between background clipping edge and border stroke.
-- -1..1 goes from inside to outside of border edge.
ui.layer.background_clip_border_offset = -1

ui.layer.border_width = 0 --no border
ui.layer.border_radius = 0 --square
ui.layer.border_color = '#0000'
-- border stroke positioning relative to box edge.
-- -1..1 goes from inside to outside of box edge.
ui.layer.border_offset = -1
--draw rounded corners with a modified bezier for smoother line-to-arc
--transitions. kappa=1 uses circle arcs instead.
ui.layer.border_radius_kappa = 1.2

function ui.layer:after_init(ui, t)
	self._matrix = cairo.matrix()
	self._matrix2 = cairo.matrix()
end

function ui.layer:before_free()
	self:_free_layers()
	self.parent = false
end

--matrix-affecting fields

function ui.layer:get_rel_matrix()
	return self._matrix
		:reset()
		:translate(self.x, self.y)
		:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		:scale_around(self.scale_cx, self.scale_cy, self.scale_x, self.scale_y)
end

function ui.layer:get_rel_inverse_matrix()
	return self.rel_matrix:invert()
end

--convert point from own space to parent space
function ui.layer:to_parent(x, y)
	return self.rel_matrix:point(x, y)
end

--convert point from parent space to own space
function ui.layer:from_parent(x, y)
	return self.rel_inverse_matrix:point(x, y)
end

--parent/child relationship

function ui.layer:get_parent() --child interface
	return self._parent
end

function ui.layer:set_parent(parent)
	if self._parent then
		self._parent:_remove_layer(self)
		self._parent = false
	end
	if parent then
		parent:_add_layer(self)
	end
	self._parent = parent
	self.window = parent and parent.window or parent
end

function ui.layer:get_z_order() --child interface
	return self._z_order
end

function ui.layer:set_z_order(z_order)
	self._z_order = z_order
	if self.parent then
		self.parent:_sort_layers()
	end
end

function ui.layer:_add_layer(layer) --parent interface
	self.layers = self.layers or {}
	push(self.layers, layer)
	self:_sort_layers()
	self:fire('layer_added', layer)
end

function ui.layer:_remove_layer(layer) --parent interface
	popval(self.layers, layer)
	self:fire('layer_removed', layer)
end

function ui.layer:_free_layers()
	if not self.layers then return end
	while #self.layers > 0 do
		self.layers[#self.layers]:free()
	end
end

function ui.layer:_sort_layers() --parent interface
	if not self.layers then return end
	table.sort(self.layers, function(a, b)
		return a.z_order < b.z_order
	end)
end

function ui.layer:to_window(x, y) --parent & child interface
	return self.parent:to_window(self:to_parent(x, y))
end

function ui.layer:from_window(x, y) --parent & child interface
	return self:from_parent(self.parent:from_window(x, y))
end

--mouse event handling

function ui.layer:_mousemove(mx, my, area)
	local mx, my = self:to_content(self:from_window(mx, my))
	self:fire('mousemove', mx, my, area)
end

function ui.layer:_mouseenter(mx, my, area)
	local mx, my = self:to_content(self:from_window(mx, my))
	self:fire('mouseenter', mx, my, area)
end

function ui.layer:_mouseleave()
	self:fire'mouseleave'
end

function ui.layer:_mousedown(button, mx, my, area)
	local mx, my = self:to_content(self:from_window(mx, my))
	self:fire('mousedown', button, mx, my, area)
end

function ui.layer:_mouseup(button, mx, my, area)
	local mx, my = self:to_content(self:from_window(mx, my))
	self:fire('mouseup', button, mx, my, area)
end

function ui.layer:mouse_pos()
	if not self.window.mouse_x then
		return false, false
	end
	return self:to_content(self:from_window(self.window:mouse_pos()))
end

function ui.layer:get_mouse_x() return (select(1, self:mouse_pos())) end
function ui.layer:get_mouse_y() return (select(2, self:mouse_pos())) end

--layers geometry, drawing and hit testing

function ui.layer:layers_bounding_box()
	local x, y, w, h = 0, 0, 0, 0
	if self.layers then
		for _,layer in ipairs(self.layers) do
			x, y, w, h = box2d.bounding_box(x, y, w, h, layer:bounding_box())
		end
	end
	return x, y, w, h
end

function ui.layer:draw_layers() --called in content space
	if not self.layers then return end
	for i = 1, #self.layers do
		self.layers[i]:draw()
	end
end

function ui.layer:hit_test_layers(x, y) --called in content space
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local widget, area = self.layers[i]:hit_test(x, y)
		if widget then
			return widget, area
		end
	end
end

--border geometry and drawing

--border edge widths relative to box rect at %-offset in border width.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
--returned widths are positive when inside and negative when outside box rect.
function ui.layer:_border_edge_widths(offset)
	local o = self.border_offset + offset + 1
	local w1 = lerp(o, -1, 1, self.border_width_left, 0)
	local h1 = lerp(o, -1, 1, self.border_width_top, 0)
	local w2 = lerp(o, -1, 1, self.border_width_right, 0)
	local h2 = lerp(o, -1, 1, self.border_width_bottom, 0)
	--adjust overlapping widths by scaling them down proportionally.
	if w1 + w2 > self.w or h1 + h2 > self.h then
		local scale = math.min(self.w / (w1 + w2), self.h / (h1 + h2))
		w1 = w1 * scale
		h1 = h1 * scale
		w2 = w2 * scale
		h2 = h2 * scale
	end
	return w1, h1, w2, h2
end

function ui.layer:border_pos(offset)
	local w, h = self:_border_edge_widths(offset)
	return w, h
end

--border rect at %-offset in border width.
function ui.layer:border_rect(offset)
	local w1, h1, w2, h2 = self:_border_edge_widths(offset)
	local w = self.w - w2 - w1
	local h = self.h - h2 - h1
	return w1, h1, w, h
end

--corner radius at pixel offset from the stroke's center on one dimension.
local function offset_radius(r, o)
	return r > 0 and math.max(0, r + o) or 0
end

--border rect at %-offset in border width, plus radii of rounded corners.
function ui.layer:border_round_rect(offset)
	local k = self.border_radius_kappa

	local x1, y1, w, h = self:border_rect(0) --border at stroke center
	local X1, Y1, W, H = self:border_rect(offset) --border at given offset

	local x2, y2 = x1 + w, y1 + h
	local X2, Y2 = X1 + W, Y1 + H

	local r1 = self.border_radius_top_left
	local r2 = self.border_radius_top_right
	local r3 = self.border_radius_bottom_right
	local r4 = self.border_radius_bottom_left

	--offset the radii to preserve curvature at offset.
	local r1x = offset_radius(r1, x1-X1)
	local r1y = offset_radius(r1, y1-Y1)
	local r2x = offset_radius(r2, X2-x2)
	local r2y = offset_radius(r2, y1-Y1)
	local r3x = offset_radius(r3, X2-x2)
	local r3y = offset_radius(r3, Y2-y2)
	local r4x = offset_radius(r4, x1-X1)
	local r4y = offset_radius(r4, Y2-y2)

	--remove degenerate arcs.
	if r1x == 0 or r1y == 0 then r1x = 0; r1y = 0 end
	if r2x == 0 or r2y == 0 then r2x = 0; r2y = 0 end
	if r3x == 0 or r3y == 0 then r3x = 0; r3y = 0 end
	if r4x == 0 or r4y == 0 then r4x = 0; r4y = 0 end

	--adjust overlapping radii by scaling them down proportionally.
	local maxx = math.max(r1x + r2x, r3x + r4x)
	local maxy = math.max(r1y + r4y, r2y + r3y)
	if maxx > W or maxy > H then
		local scale = math.min(W / maxx, H / maxy)
		r1x = r1x * scale
		r1y = r1y * scale
		r2x = r2x * scale
		r2y = r2y * scale
		r3x = r3x * scale
		r3y = r3y * scale
		r4x = r4x * scale
		r4y = r4y * scale
	end

	return
		X1, Y1, W, H,
		r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y,
		k
end

--De Casteljau split of a cubic bezier at time t (from path2d).
local function bezier_split(first, t, x1, y1, x2, y2, x3, y3, x4, y4)
	local mt = 1-t
	local x12 = x1 * mt + x2 * t
	local y12 = y1 * mt + y2 * t
	local x23 = x2 * mt + x3 * t
	local y23 = y2 * mt + y3 * t
	local x34 = x3 * mt + x4 * t
	local y34 = y3 * mt + y4 * t
	local x123 = x12 * mt + x23 * t
	local y123 = y12 * mt + y23 * t
	local x234 = x23 * mt + x34 * t
	local y234 = y23 * mt + y34 * t
	local x1234 = x123 * mt + x234 * t
	local y1234 = y123 * mt + y234 * t
	if first then
		return x1, y1, x12, y12, x123, y123, x1234, y1234 --first curve
	else
		return x1234, y1234, x234, y234, x34, y34, x4, y4 --second curve
	end
end

local kappa = 4 / 3 * (math.sqrt(2) - 1)

--more-aesthetically-pleasing elliptic arc. only for 45deg and 90deg sweeps!
local function bezier_qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	cr:save()
	cr:translate(cx, cy)
	cr:scale(rx / ry, 1)
	cr:rotate(math.floor(math.min(q1, q1 + qlen) - 2) * math.pi / 2)
	local r = ry
	local k = r * kappa * k
	local x1, y1, x2, y2, x3, y3, x4, y4 = 0, -r, k, -r, r, -k, r, 0
	if qlen < 0 then --reverse curve
		x1, y1, x2, y2, x3, y3, x4, y4 = x4, y4, x3, y3, x2, y2, x1, y1
		qlen = math.abs(qlen)
	end
	if qlen ~= 1 then
		assert(qlen == .5)
		local first = q1 == math.floor(q1)
		x1, y1, x2, y2, x3, y3, x4, y4 =
			bezier_split(first, qlen, x1, y1, x2, y2, x3, y3, x4, y4)
	end
	cr:line_to(x1, y1)
	cr:curve_to(x2, y2, x3, y3, x4, y4)
	cr:restore()
end

--draw an eliptic arc: q1 is the quadrant starting top-left going clockwise.
--qlen is in 90deg units and can only be +/- .5 or 1 if k ~= 1.
local function qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	if rx == 0 or ry == 0 then --null arcs need a line to the first endpoint
		assert(rx == 0 and ry == 0)
		cr:line_to(cx, cy)
	elseif k == 1 then --geometrically-correct elliptic arc
		local q2 = q1 + qlen
		local a1 = (q1 - 3) * math.pi / 2
		local a2 = (q2 - 3) * math.pi / 2
		local arc = a1 < a2 and cr.elliptic_arc or cr.elliptic_arc_negative
		arc(cr, cx, cy, rx, ry, 0, a1, a2)
	else
		bezier_qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	end
end

--trace the border contour path at offset.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
function ui.layer:border_path(offset)
	local cr = self.window.cr
	local x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(offset)
	local x2, y2 = x1 + w, y1 + h
	cr:move_to(x1, y1+r1y)
	qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, 1, k) --tl
	qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, 1, k) --tr
	qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, 1, k) --br
	qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, 1, k) --bl
	cr:close_path()
end

function ui.layer:border_visible()
	return
		self.border_width_left ~= 0
		or self.border_width_top ~= 0
		or self.border_width_right ~= 0
		or self.border_width_bottom ~= 0
end

function ui.layer:draw_border()
	if not self:border_visible() then return end
	local cr = self.window.cr

	--seamless drawing when all side colors are the same.
	if self.border_color_left == self.border_color_top
		and self.border_color_left == self.border_color_right
		and self.border_color_left == self.border_color_bottom
	then
		cr:new_path()
		cr:fill_rule'even_odd'
		self:border_path(-1)
		self:border_path(1)
		cr:rgba(self.ui:color(self.border_color_bottom))
		cr:fill()
		return
	end

	--complicated drawing of each side separately.
	--still shows seams on adjacent sides of the same color.
	local x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(-1)
	local X1, Y1, W, H, R1X, R1Y, R2X, R2Y, R3X, R3Y, R4X, R4Y, K =
		self:border_round_rect(1)

	local x2, y2 = x1 + w, y1 + h
	local X2, Y2 = X1 + W, Y1 + H

	if self.border_color_left then
		cr:new_path()
		cr:move_to(x1, y1+r1y)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, .5, k)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 1.5, -.5, K)
		cr:line_to(X1, Y2-R4Y)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 5, -.5, K)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_left))
		cr:fill()
	end

	if self.border_color_top then
		cr:new_path()
		cr:move_to(x2-r2x, y1)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, .5, k)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 2.5, -.5, K)
		cr:line_to(X1+R1X, Y1)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 2, -.5, K)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_top))
		cr:fill()
	end

	if self.border_color_right then
		cr:new_path()
		cr:move_to(x2, y2-r3y)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, .5, k)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 3.5, -.5, K)
		cr:line_to(X2, Y1+R2Y)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 3, -.5, K)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_right))
		cr:fill()
	end

	if self.border_color_bottom then
		cr:new_path()
		cr:move_to(x1+r4x, y2)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, .5, k)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 4.5, -.5, K)
		cr:line_to(X2-R3X, Y2)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 4, -.5, K)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_bottom))
		cr:fill()
	end
end

--background geometry and drawing

function ui.layer:background_visible()
	return (self.background_type == 'color' and self.background_color)
		or ((self.background_type == 'gradient'
			or self.background_type == 'radial_gradient')
			and self.background_colors and #self.background_colors > 0)
		or (self.background_type == 'image' and self.background_image)
		and true or false
end

function ui.layer:background_rect()
	return self:border_rect(self.background_clip_border_offset)
end

function ui.layer:background_path()
	self:border_path(self.background_clip_border_offset)
end

function ui.layer:set_background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

function ui.layer:paint_background()
	local cr = self.window.cr
	cr:operator(self.background_operator)
	local bg_type = self.background_type
	if bg_type == 'color' then
		cr:rgba(self.ui:color(self.background_color))
		cr:paint()
		return
	end
	local patt
	if bg_type == 'gradient' or bg_type == 'radial_gradient' then
		if bg_type == 'gradient' then
			patt = self.ui:linear_gradient(
				self.background_x1,
				self.background_y1,
				self.background_x2,
				self.background_y2,
				unpack(self.background_colors))
		elseif bg_type == 'radial_gradient' then
			patt = self.ui:radial_gradient(
				self.background_cx1,
				self.background_cy1,
				self.background_r1,
				self.background_cx2,
				self.background_cy2,
				self.background_r2,
				unpack(self.background_colors))
		end
	elseif bg_type == 'image' then
		local img = self.ui:image(self.background_image)
		if not img then return end
		patt = img.patt
	else
		assert(false, 'invalid background type %s', tostring(bg_type))
	end
	patt:matrix(
		self._matrix:reset()
			:translate(
				self.background_x,
				self.background_y)
			:rotate_around(
				self.background_rotation_cx,
				self.background_rotation_cy,
				math.rad(self.background_rotation))
			:scale_around(
				self.background_scale_cx,
				self.background_scale_cy,
				self.background_scale_x,
				self.background_scale_y)
			:invert())
	patt:extend(self.background_extend)
	cr:source(patt)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
end

--content-box geometry, drawing and hit testing

function ui.layer:padding_pos()
	local x, y = self:border_pos(-1) --inner edge
	return
		x + self.padding_left,
		y + self.padding_top
end

function ui.layer:padding_rect()
	local x, y, w, h = self:border_rect(-1) --inner edge
	return
		x + self.padding_left,
		y + self.padding_top,
		w - self.padding_left - self.padding_right,
		h - self.padding_top - self.padding_bottom
end

function ui.layer:to_content(x, y) --box space coord in content space
	local px, py = self:padding_pos()
	return x - px, y - py
end

function ui.layer:from_content(x, y) --content space coord in box space
	local px, py = self:padding_pos()
	return px + x, py + y
end

function ui.layer:draw_content() --called in content space
	self:draw_layers()
end

function ui.layer:hit_test_content(x, y) --called in content space
	return self:hit_test_layers(x, y)
end

--child interface

function ui.layer:after_draw() --called in parent's space
	if not self.visible or self.opacity == 0 then return end
	if self.opacity <= 0 then return end
	local cr = self.window.cr

	local opacity = self.opacity
	local compose = opacity < 1
	if compose then
		cr:push_group()
	else
		cr:save()
	end

	cr:matrix(cr:matrix(nil, self._matrix2):multiply(self.rel_matrix))

	local cc = self.content_clip
	local bg = self:background_visible()

	local clip = bg or cc
	if clip then
		cr:save()
		cr:new_path()
		self:background_path() --'background' clipping is implicit in 'padding'
		cr:clip()
		if bg then
			self:paint_background()
		end
		if cc == 'padding' or cc == true then
			cr:new_path()
			cr:rectangle(self:padding_rect())
			cr:clip()
		elseif not cc then --clip was only needed to draw the bg
			cr:restore()
			clip = false
		end
	end
	if not cc then
		self:draw_border()
	end
	local cx, cy = self:padding_pos()
	cr:translate(cx, cy)
	self:draw_content()
	cr:translate(-cx, -cy)
	if clip then
		cr:restore()
	end
	if cc then
		self:draw_border()
	end

	if compose then
		cr:pop_group_to_source()
		cr:paint_with_alpha(opacity)
		cr:rgb(0, 0, 0) --release source
	else
		cr:restore()
	end
end

function ui.layer:hit_test(x, y) --called in parent's space
	if not self.visible or self.opacity == 0 then return end
	local cr = self.window.cr
	local x, y = self:from_parent(x, y)
	cr:save()
	cr:identity_matrix()

	local border = self:border_visible()
	local bg = self:background_visible()
	local cc = self.content_clip

	--hit the content first if it's not clipped
	if not cc then
		local cx, cy = self:to_content(x, y)
		local widget, area = self:hit_test_content(cx, cy)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--border is drawn last so hit it first
	if border then
		cr:new_path()
		self:border_path(1)
		if cr:in_fill(x, y) then --inside border outer edge
			cr:new_path()
			self:border_path(-1)
			if not cr:in_fill(x, y) then --outside border inner edge
				cr:restore()
				return self, 'border'
			end
		elseif cc then --outside border outer edge when clipped
			cr:restore()
			return
		end
	end

	--hit background's clip area
	local in_bg
	if cc or bg then
		cr:new_path()
		self:background_path()
		in_bg = cr:in_fill(x, y)
	end

	--hit content's clip area
	local in_cc
	if cc and in_bg then --'background' clipping is implicit in 'padding'
		if cc == 'padding' or cc == true then
			cr:new_path()
			cr:rectangle(self:padding_rect())
			if cr:in_fill(x, y) then
				in_cc = true
			end
		else
			in_cc = true
		end
	end

	--hit the content
	if in_cc then
		local cx, cy = self:to_content(x, y)
		local widget, area = self:hit_test_content(cx, cy)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--hit the background if any
	if in_bg then
		return self, 'background'
	end
end

function ui.layer:bounding_box()
	x, y, w, h = self:layers_bounding_box()
	local cc = self.content_clip
	if cc then
		x, y, w, h = box.clip(x, y, w, h, self:background_rect())
		if cc == 'padding' or cc == true then
			x, y, w, h = box.clip(x, y, w, h, self:padding_rect())
		end
	else
		if self:background_visible() then
			x, y, w, h = box2d.bounding_box(x, y, w, h, self:background_rect())
		end
		if self:border_visible() then
			x, y, w, h = box2d.bounding_box(x, y, w, h, self:border_rect(1))
		end
	end
	return x, y, w, h
end

--element interface

function ui.layer:frame_clock()
	return self.window:frame_clock()
end

function ui.layer:invalidate()
	if self.window then
		self.window:invalidate()
	end
end

--the `hot` property which is managed by the window

function ui.layer:get_hot()
	return self.window.hot_widget == self
end

function ui.layer:after_mouseenter()
	if not self.window.active_widget then
		self:settags'hot'
	end
end

function ui.layer:after_mouseleave()
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

--utils in content space to use from draw_content() and hit_test_content()

function ui.layer:rect() return 0, 0, self.w, self.h end --the box itself
function ui.layer:size() return self.w, self.h end

function ui.layer:hit(x, y, w, h)
	local mx, my = self:mouse_pos()
	return box2d.hit(mx, my, x, y, w, h)
end

function ui.layer:from_origin(x, y) --from box space to content space
	local px, py = self:padding_pos()
	return x-px, y-py
end

function ui.layer:content_size()
	return select(3, self:padding_rect())
end

function ui.layer:content_rect() --in content space
	return 0, 0, select(3, self:padding_rect())
end

function ui.layer:get_cw() return (select(3, self:padding_rect())) end
function ui.layer:get_ch() return (select(4, self:padding_rect())) end


function ui.layer:setfont(family, weight, slant, size, color)
	self.window:setfont(
		family or self.font_family,
		weight or self.font_weight,
		slant or self.font_slant,
		size or self.text_size)
	self.window.cr:rgba(self.ui:color(color or self.text_color))
end

--buttons --------------------------------------------------------------------

ui.button = oo.button(ui.layer)

ui.button.background_color = '#444'
ui.button.border_color = '#888'
ui.button.border_width = 1

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
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

function ui.button:before_draw_content()
	if self.text then
		self.window:textbox(0, 0, self.w, self.h, self.text,
			self.font_family, self.font_weight, self.font_slant, self.text_size,
			self.line_spacing, self.text_color, 'center', 'center')
	end
end

--scrollbars -----------------------------------------------------------------

ui.scrollbar = oo.scrollbar(ui.layer)

ui.scrollbar:_addtags'scrollbar'

ui.scrollbar._vertical = true
ui.scrollbar.step = 1
ui.scrollbar.thickness = 20
ui.scrollbar.min_width = 0
ui.scrollbar.autohide = true
ui.scrollbar.background_color = '#222'
ui.scrollbar.grabbar_background_color = '#444'
ui.scrollbar.opacity = 0

ui.scrollbar.grabbar = ui.layer --class for the grabbar

ui:style('scrollbar', {
	transition_background_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
	transition_opacity = true,
	transition_delay_opacity = .5,
	transition_duration_opacity = 1,
})

ui:style('scrollbar near', {
	opacity = 1,
	transition_opacity = true,
	transition_duration_opacity = .5,
	transition_delay_opacity = 0,
})

ui:style('scrollbar hot', {
	grabbar_background_color = '#ccc',
	transition_grabbar_background_color = true,
})

ui:style('scrollbar active', {
	grabbar_background_color = '#fff',
	transition_grabbar_background_color = true,
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
	return true --stub
end

function ui.scrollbar:after_init(ui, t)

	self.thickness = self.thickness --auto-set w/h

	self.offset = client_offset_clamp(self.offset or 0, self.size,
		self.vertical and self.ch or self.cw, self.step)

	local bx, by, bw, bh = self:grabbar_rect()
	self.grabbar = self.grabbar(self.ui, {
		id = self:_subtag'grabbar', parent = self,
		x = bx, y = by, w = bw, h = bh,
		background_color = '#ff0',
	})

	self.window:on({'mousemove', self}, function(win, mx, my)
		local mx, my = self:from_window(mx, my)
		self:_autohide_mousemove(mx, my)
	end)

	self.window:on({'mouseleave', self}, function(win)
		self:_autohide_mouseleave()
	end)

	if not self.autohide then
		self:settags'near'
	end
end

function ui.scrollbar:before_free()
	self.window:off{nil, self}
end

function ui.scrollbar:grabbar_rect()
	local bx, by, bw, bh
	if self.vertical then
		by, bh = bar_segment(self.ch, self.size, self.offset, self.min_width)
		bx, bw = 0, self.cw
	else
		bx, bw = bar_segment(self.cw, self.size, self.offset, self.min_width)
		by, bh = 0, self.ch
	end
	return bx, by, bw, bh
end

function ui.scrollbar:_autohide_mousemove(mx, my)
	local near = not self.autohide or self:hit_test_near(mx, my)
	if near and not self._to1 then
		self._to1 = true
		self._to0 = false
		self:settags'near'
	elseif not near and not self._to0 then
		self._to0 = true
		self._to1 = false
		self:settags'-near'
	end
end

function ui.scrollbar:_autohide_mouseleave()
	if self.autohide and not self._to0 then
		self._to0 = true
		self._to1 = false
		self:settags'-near'
	end
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
			self.offset = client_offset(by, self.ch, bh, self.size, self.step)
		else
			local bx = bar_offset_clamp(mx - self._grab, self.w, bw)
			self.offset = client_offset(bx, self.cw, bw, self.size, self.step)
		end
		if self.offset ~= offset then
			self:fire('changed', self.offset, offset)
			self:invalidate()
		end
	end
end

function ui.scrollbar:before_draw_content()
	local bx, by, bw, bh = self:grabbar_rect()
	if bw < self.w or bh < self.h then
		--self.grabbar_background_color
		--self.window.cr:rectacngle(bx, by, bw, bh, )
	end
end

--`vertical` and `horizontal` tags based on `vertical` property

function ui.scrollbar:get_vertical()
	return self._vertical
end

function ui.scrollbar:set_vertical(vertical)
	self._vertical = vertical
	self:settags(vertical and 'vertical' or '-vertical')
	self:settags(vertical and '-horizontal' or 'horizontal')
end

--scrollbox ------------------------------------------------------------------

ui.scrollbox = oo.scrollbox(ui.layer)

ui.scrollbox.vscroll = 'always'
ui.scrollbox.hscroll = 'always'
ui.scrollbox.scroll_width = 20
ui.scrollbox.page_size = 120

--classes of sub-components
ui.scrollbox.vscrollbar = ui.scrollbar
ui.scrollbox.hscrollbar = ui.scrollbar
ui.scrollbox.content_layer = ui.layer

function ui.scrollbox:after_init(ui, t)

	self.vscrollbar = self.vscrollbar(self.ui, {
		id = self:_subtag'vertical_scrollbar', parent = self, vertical = true,
		h = 0, size = 500, z_order = 100,
	})

	self.hscrollbar = self.hscrollbar(self.ui, {
		id = self:_subtag'horizontal_scrollbar', parent = self, vertical = false,
		w = 0, size = 500, z_order = 100,
	})

	function self.vscrollbar:hit_test_near(x, y)
		return true
	end

	function self.hscrollbar:hit_test_near(x, y)
		return true
	end

	local dw = self.vscrollbar.w
	local dh = self.hscrollbar.h
	local cw = self.w - (self.vscrollbar.autohide and 0 or dw)
	local ch = self.h - (self.hscrollbar.autohide and 0 or dh)

	self.vscrollbar.x = cw - (self.vscrollbar.autohide and dw or 0)
	self.vscrollbar.h = ch
	self.hscrollbar.y = ch - (self.vscrollbar.autohide and dh or 0)
	self.hscrollbar.w = cw

	self.content = self.content_layer(self.ui, {
		id = self:_subtag'content', parent = self,
		x = 0, y = 0, w = cw, h = ch,
	})

end

function ui.scrollbox:before_draw_content()
	local cr = self.window.cr
end

--tab ------------------------------------------------------------------------

ui.tab = oo.tab(ui.layer)

function ui.tab:border_path()
	--
end

--tab list -------------------------------------------------------------------

ui.tablist = oo.tablist(ui.layer)

function ui.tablist:widget_added(widget)
	--
end

function ui.tablist:before_draw_content()

end

return ui
