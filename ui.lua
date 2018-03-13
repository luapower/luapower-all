
--extensible UI toolkit with layouts, styles and animations.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'ui_demo'; return end

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

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

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

function dr:fillstroke(fill_color, stroke_color, line_width)
	local cr = self.cr
	if fill_color then
		self:_setcolor(fill_color)
		if stroke_color then
			cr:fill_preserve()
		else
			cr:fill()
		end
	end
	if stroke_color then
		self:_setcolor(stroke_color)
		cr:line_width(line_width)
		cr:stroke()
	end
end

--paths

local kappa = 4 / 3 * (math.sqrt(2) - 1)
local qrad = math.pi / 2

--draw a 90deg-arc. q=1 is top-left quarter going clockwise.
local function qarc(cr, cx, cy, rx, ry, q, k)
	if k == 1 then
		if rx ~= ry then
			cr:save()
			cr:scale(rx / ry, 1)
		end
		cr:arc(cx, cy, ry, (q - 3) * qrad, (q - 2) * qrad)
		if rx ~= ry then
			cr:restore()
		end
	else
		--draw a better-looking arc that is not really circular.
		cr:save()
		cr:translate(cx, cy)
		cr:rotate((q - 2) * qrad)
		local k = r * kappa * k
		--TODO: rx, ry
		cr:curve_to(k, -r, r, -k, r, 0)
		cr:restore()
	end
end

function dr:round_rect_path(x, y, w, h,
	r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y,
	k
)
	local cr = self.cr
	local x1, y1, x2, y2 = x, y, x + w, y + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	cr:move_to(x1, y1+r1y)
	qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, k); cr:line_to(x2-r2x, y1)
	qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, k); cr:line_to(x2, y2-r3y)
	qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, k); cr:line_to(x1+r4x, y2)
	qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, k)
	cr:close_path()
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

	self.cr:restore()
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
	update(self, t)
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

--windows --------------------------------------------------------------------

ui.window = oo.window(ui.element)

ui.window.opacity = 1 --TODO: set native_window's opacity

ui:style('window_layer', {
	background_color = '#000',
})

function ui.window:after_init(ui, t)

	self.dr = ui:draw()
	local win = self.native_window

	self.x, self.y, self.w, self.h = self.native_window:client_rect()

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false

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

	self.layer = self.ui:layer{
		id = self:_subtag'layer', x = 0, y = 0, w = self.w, h = self.h,
		parent = self, content_clip = false,
	}
end

function ui.window:before_free()
	self.native_window:off'.ui'
	self.hot_widget = false
	self.active_widget = false
	self.layer:free()
	self.dr:free()
	self.native_window = false
end

--`hot` and `active` widget logic and mouse events routing

function ui.window:_set_hot_widget(widget, mx, my)
	if self.hot_widget == widget then
		return
	end
	if self.hot_widget then
		self.hot_widget:fire'mouseleave'
	end
	if widget then
		--the hot widget is still the old widget when entering the new widget
		local mx, my = widget:from_window(mx, my)
		widget:fire('mouseenter', mx, my)
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
		local mx, my = widget:from_window(mx, my)
		widget:fire('mousemove', mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my)
		if widget then
			local mx, my = widget:from_window(mx, my)
			widget:fire('mousemove', mx, my)
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
		widget:fire'mouseleave'
	end
	self:_set_hot_widget(false)
end

function ui.window:_mousedown(button, mx, my)
	self.mouse_x = mx
	self.mouse_y = my
	self:fire('mousedown', button, mx, my)
	local widget = self.active_widget
	if widget then
		local mx, my = widget:from_window(mx, my)
		widget:fire('mousedown', button, mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my)
		if widget then
			local mx, my = widget:from_window(mx, my)
			widget:fire('mousedown', button, mx, my)
		end
	end
end

function ui.window:_mouseup(button, mx, my)
	self.mouse_x = mx
	self.mouse_y = my
	self:fire('mouseup', button, mx, my)
	local widget = self.active_widget
	if widget then
		local mx, my = widget:from_window(mx, my)
		widget:fire('mouseup', button, mx, my)
	end
	if not self.active_widget then
		local widget = self:hit_test(mx, my)
		self:_set_hot_widget(widget, mx, my)
		if widget then
			local mx, my = widget:from_window(mx, my)
			widget:fire('mouseup', button, mx, my)
		end
	end
end

function ui.window:hit_test(x, y)
	return self.layer:hit_test(x, y)
end

--rendering

function ui.window:after_draw()
	if not self.visible then return end
	local dr = self.dr
	local cr = dr.cr
	cr:save()
	self.layer:draw()
	cr:restore()
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

function ui.window:bounding_box()
	return box2d.bound_box(0, 0, self.w, self.h, self.layer:bounding_box())
end

--layers ---------------------------------------------------------------------

ui.layer = oo.layer(ui.element)

ui.layer._x = 0
ui.layer._y = 0
ui.layer._rotation = 0
ui.layer._rotation_cx = 0
ui.layer._rotation_cy = 0
ui.layer._scale = 1
ui.layer._scale_cx = 0
ui.layer._scale_cy = 0

ui.layer._z_order = 0

ui.layer.opacity = 1

ui.layer.content_clip = 'padding' --'padding', 'background', false

ui.layer.padding_left = 0
ui.layer.padding_top = 0
ui.layer.padding_right = 0
ui.layer.padding_bottom = 0

ui.layer.background_color = nil --transparent
ui.layer.background_origin = '' --TODO
ui.layer.background_clip = 'border' --'padding', 'border'
-- border overlapping offset when clipping the background
-- -1..1 goes from inside to outside of border edge
ui.layer.background_clip_border_offset = -1

ui.layer.border_offset = -1 -- -1..1 goes from inside to outside of rect() edge
--ui.layer.border_color = '#fff'
--ui.layer.border_width = 0
ui.layer.border_color_left = '#fff'
ui.layer.border_color_top = '#fff'
ui.layer.border_color_right = '#fff'
ui.layer.border_color_bottom = '#fff'
ui.layer.border_width_left = 0
ui.layer.border_width_top = 0
ui.layer.border_width_right = 0
ui.layer.border_width_bottom = 0
ui.layer.border_radius_top_left = 0
ui.layer.border_radius_top_right = 0
ui.layer.border_radius_bottom_right = 0
ui.layer.border_radius_bottom_left = 0
ui.layer.border_radius_kappa = 1.2 --smoother line-to-arc transition

function ui.layer:after_init(ui, t)
	self._matrix = cairo.matrix()
	self._inverse_matrix = cairo.matrix()
	self._matrix_valid = false
end

function ui.layer:before_free()
	self:_free_layers()
	self.parent = false
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

function ui.layer:_hit_test_layers(x, y) --(x, y) are in content space
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local layer = self.layers[i]
		local x, y = layer:from_parent(x, y)
		local widget = layer:hit_test(x, y)
		if widget then
			return widget
		end
	end
end

function ui.layer:_layers_bounding_box()
	local x, y, w, h = 0, 0, 0, 0
	if self.layers then
		for _,layer in ipairs(self.layers) do
			x, y, w, h = box2d.bounding_box(x, y, w, h, layer:bounding_box())
		end
	end
	return x, y, w, h
end

function ui.layer:_draw_layers()
	if not self.layers then return end
	for i = 1, #self.layers do
		local layer = self.layers[i]
		layer:draw()
	end
end

function ui.layer:to_window(x, y) --parent & child interface
	return self.parent:to_window(self:to_parent(x, y))
end

function ui.layer:from_window(x, y) --parent & child interface
	return self:from_parent(self.parent:from_window(x, y))
end

function ui.layer:mouse_pos() --parent interface
	local mx, my = self.parent:mouse_pos()
	if not mx then
		return false, false
	end
	return self:from_parent(mx, my)
end

--matrix-affecting fields

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
end
getset'x'
getset'y'
getset'w'
getset'h'
getset'rotation_cx'
getset'rotation_cy'
getset'rotation'
getset'scale'
getset'scale_cx'
getset'scale_cy'

function ui.layer:_check_matrix()
	if self._matrix_valid then return end
	local m, im = self._matrix, self._inverse_matrix
	local ox, oy = self:to_origin(0, 0)
	m:reset()
		:translate(self.x, self.y)
		:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		:scale_around(self.scale_cx, self.scale_cy, self.scale)
		:translate(-ox, -oy)
	im:reset(m):invert()
	self._matrix_valid = true
end

function ui.layer:get_matrix() --matrix is in content space
	self:_check_matrix()
	return self._matrix
end

function ui.layer:get_inverse_matrix()
	self:_check_matrix()
	return self._inverse_matrix
end

function ui.layer:to_parent(x, y)
	return self.matrix:point(x, y)
end

function ui.layer:from_parent(x, y)
	return self.inverse_matrix:point(x, y)
end

--box model geometry (borders, background, padding, clipping)

--border edge offsets relative to rect() at a particular stroke width offset.
--offset is in -1..1 in stroke's width, -1=inner edge, 0=center, 1=outer edge.
function ui.layer:_border_edge_offsets_top_left(offset)
	local o = self.border_offset + offset + 1
	return
		lerp(o, -1, 1, self.border_width_left, 0),
		lerp(o, -1, 1, self.border_width_top, 0)
end

function ui.layer:_border_edge_offsets_bottom_right(offset)
	local o = self.border_offset + offset + 1
	return
		lerp(o, -1, 1, self.border_width_right, 0),
		lerp(o, -1, 1, self.border_width_bottom, 0)
end

function ui.layer:border_pos(offset) --relative to rect()
	return self:_border_edge_offsets_top_left(offset)
end

function ui.layer:border_rect(offset) --relative to rect()
	local w1, h1 = self:_border_edge_offsets_top_left(offset)
	local w2, h2 = self:_border_edge_offsets_bottom_right(offset)
	local w = self.w - w2 - w1
	local h = self.h - h2 - h1
	return w1, h1, w, h
end

function ui.layer:padding_pos() --relative to rect()
	local x, y = self:border_pos(-1) --inner widths
	return
		x + self.padding_left,
		y + self.padding_top
end

function ui.layer:padding_rect() --relative to rect()
	local x, y, w, h = self:border_rect(-1) --inner widths
	return
		x + self.padding_left,
		y + self.padding_top,
		w - self.padding_left - self.padding_right,
		h - self.padding_top - self.padding_bottom
end

function ui.layer:to_origin(x, y) --in content space
	local px, py = self:padding_pos()
	return x-px, y-py
end

function ui.layer:content_size()
	local _, _, w, h = self:padding_rect()
	return w, h
end

function ui.layer:content_rect() --in content space
	local _, _, w, h = self:padding_rect()
	return 0, 0, w, h
end

function ui.layer:get_cw() return (select(3, self:padding_rect())) end
function ui.layer:get_ch() return (select(4, self:padding_rect())) end

--compute corner radius at offset in pixels from the stroke's center.
local function offset_radius(offset, k, r)
	if r <= 0 then return 0 end
	local r = math.max(0, r + offset)
	if k > 1 then
		--NOTE: this is only an approximate empirical formula. It is needed
		--when offsetting rectangles with rounded corners which are not perfect
		--circle arcs (k > 1), in order to clip on the inside of the stroke.
		r = r * lerp(offset, 0, 100, 1, 1.5)
	end
	return r
end

--offset is in -1..1 in stroke's width, -1=inner edge, 0=center, 1=outer edge.
function ui.layer:border_round_rect(offset)
	local bow = -lerp(offset, -1, 1, 0, self.border_width)
	local offset = -(self:border_inner_width() + bow)
	local x, y = self:to_origin(0, 0)
	local x, y, w, h = box2d.offset(offset, x, y, self.w, self.h)
	--find the offset from the border's stroke center to compute corner radius.
	local offset = -(self.border_width / 2 + bow)
	local k = self.border_radius_kappa
	return
		x, y, w, h,
		offset_radius(offset, k, self.border_radius_top_left),
		offset_radius(offset, k, self.border_radius_top_right),
		offset_radius(offset, k, self.border_radius_bottom_right),
		offset_radius(offset, k, self.border_radius_bottom_left),
		k
end

--child interface

function ui.layer:hit_test(x, y) --(x, y) are in content space
	return self:_hit_test_layers(x, y) --TODO: hit diff. rects
		or (box2d.hit(x, y, self:content_rect()) and self)
end

function ui.layer:bounding_box()
	if self.content_clip then
		--TODO: it's more complicated than this with rounded corners and border
		return box2d.bounding_box(self.x, self.y, self.w, self.h,
			self:_layers_bounding_box())
	else
		return self:_layers_bounding_box()
	end
end

function ui.layer:content_clip_path()
	--
end

function ui.layer:border_path()
	--
end

function ui.layer:draw_content()
	self:_draw_layers()
end

function ui.layer:after_draw()
	if not self.visible then return end
	if self.opacity <= 0 then return end

	local dr = self.window.dr
	local cr = dr.cr

	local opacity = self.opacity
	local compose = opacity < 1
	if compose then
		cr:push_group()
	else
		cr:save()
	end

	cr:matrix(cr:matrix():multiply(self.matrix)) --TOOD: sinked?

	if self.content_clip or self.background_color then

		if self.border_radius_top_left == 0
			and self.border_radius_top_right == 0
			and self.border_radius_bottom_right == 0
			and self.border_radius_bottom_left == 0
		then
			cr:rectangle(self:content_rect())
		else
			dr:round_rect_path(self:border_round_rect(self.background_clip_border_offset))
		end

		if self.content_clip then
			cr:save()
			cr:clip_preserve()
			if self.background_clip == 'padding' then
				cr:clear_path()
				cr:rectangle(self:content_rect())
				self:clip()
			end
			if self.content_clip == 'padding' then
				--clip some more
			end
		end
		if self.background_color then
			dr:fillstroke(self.background_color)
		end
	end

	self:draw_content()

	if self.content_clip then
		cr:restore()
	end

	if self.border_color and self.border_width ~= 0 then
		local ox, oy = self:to_origin(0, 0)
		cr:translate(ox, oy)
		local offset = self.border_width * self.border_offset / 2
		local x, y, w, h = box2d.offset(offset, 0, 0, self.w, self.h)
		dr:rect_path(x, y, w, h,
			self.border_radius_top_left,
			self.border_radius_top_right,
			self.border_radius_bottom_right,
			self.border_radius_bottom_left,
			self.border_radius_kappa
		)
		dr:fillstroke(nil, self.border_color, math.abs(self.border_width))
	end

	if compose then
		cr:pop_group_to_source()
		cr:paint_with_alpha(opacity)
		cr:rgb(0, 0, 0) --release source
	else
		cr:restore()
	end
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

--sugar & utils

function ui.layer:rect() return 0, 0, self.w, self.h end
function ui.layer:size() return self.w, self.h end

function ui.layer:get_mouse_x() return (select(1, self:mouse_pos())) end
function ui.layer:get_mouse_y() return (select(2, self:mouse_pos())) end

function ui.layer:hit(x, y, w, h)
	local mx, my = self:mouse_pos()
	return box2d.hit(mx, my, x, y, w, h)
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
		local mx, my = self:from_parent(mx, my)
		self:_autohide_mousemove(mx, my)
	end)

	self.window:on({'mouseleave', self}, function(win, mx, my)
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
	local dr = self.window.dr
	local bx, by, bw, bh = self:grabbar_rect()
	if bw < self.w or bh < self.h then
		--dr:rect(bx, by, bw, bh, self.grabbar_background_color)
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
	local cr = self.window.dr.cr
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
