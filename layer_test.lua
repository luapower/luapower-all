
local ffi = require'ffi'
local time = require'time'
local testui = require'testui'
local glue = require'glue'
local bundle = require'bundle'
local layer = require'layer'
local color = require'color'
local pp = require'pp'
local u = require'utf8quot'
local cairo = require'cairo'
local push, pop = table.insert, table.remove

--utils ----------------------------------------------------------------------

local function save_table(file, t)
	assert(glue.writefile(file,
		'return '..pp.format(t, {indent = '\t', sort_keys = true})))
end

local function load_table(file)
	local chunk = loadfile(file)
	return chunk and chunk()
end

--const state ----------------------------------------------------------------

local fonts = {}
fonts[1] = assert(bundle.load'media/fonts/OpenSans-Regular.ttf')
fonts[2] = assert(bundle.load'media/fonts/Amiri-Regular.ttf')

local function load_font(font_id, file_data_buf, file_size_buf)
	local s = assert(fonts[font_id+1])
	file_data_buf[0] = ffi.cast('void*', s)
	file_size_buf[0] = #s
end

local function unload_font(font_id, file_data_buf, file_size_buf)
	--nothing
end

assert(layer.memtotal() == 0)

local lib = layer.layerlib(load_font, unload_font)

local opensans = lib:font()
local amiri    = lib:font()

local default_e = lib:layer()

local lorem_ipsum = bundle.load('lorem_ipsum.txt')
local test_texts = {
	[''] = '',
	lorem_ipsum = lorem_ipsum,
	hello = 'Hello World!',
	parbreak = u'Hey\nYou&ps;New Paragraph',
}
local test_text_names = glue.index(test_texts)

local outlen = 65535
local out = ffi.new('char[?]', outlen)
local function utf8_text(e)
	local n = e:get_text_utf8(out, outlen)
	return n > 0 and ffi.string(out, n) or nil
end

--global state ---------------------------------------------------------------

local top_e
local selected_layer_path = {}
local e, hit_e, hit_area

local sessions = {}
local session_number
local continuous_repaint
local layer_changed = false
local draw_changed_dt = 0
local draw_fps_t, draw_fps_dt = 0, 0
local repaint_fps_t, repaint_fps_dt = 0, 0

--layer tree (de)serialization -----------------------------------------------

local function serialize_layer(e)

	--serialize a list of sub-objects (shadows, text spans, etc.)
	local function list(e, n, fields)
		if n == 0 then return end
		local dt = {}
		for i = 0, n-1 do
			local t = {}
			for k, convert in glue.sortedpairs(fields) do
				local v = e['get_'..k](e, i)
				local v0 = default_e['get_'..k](default_e, 0)
				if type(convert) == 'function' then
					v = convert(v)
					v0 = convert(v0)
				end
				if v ~= v0 then
					t[k] = v
				end
			end
			dt[i+1] = t
		end
		--remove trailing empty elements.
		while #dt > 0 and next(dt[#dt]) == nil do
			pop(dt)
		end
		if #dt == 0 then return end
		return dt
	end

	local function cstring(p, len)
		return p ~= nil and ffi.string(p, len) or nil
	end

	--serialize layer properties.
	local t = {}
	t.x = e.x
	t.y = e.y
	t.w = e.w
	t.h = e.h
	t.min_cw = e.min_cw
	t.min_ch = e.min_ch
	t.align_x = e.align_x
	t.align_y = e.align_y
	t.padding_left   = e.padding_left
	t.padding_top    = e.padding_top
	t.padding_right  = e.padding_right
	t.padding_bottom = e.padding_bottom
	t.rotation    = e.rotation
	t.rotation_cx = e.rotation_cx
	t.rotation_cy = e.rotation_cy
	t.scale       = e.scale
	t.scale_cx    = e.scale_cx
	t.scale_cy    = e.scale_cy
	t.visible     = e.visible
	t.operator    = e.operator
	t.clip_content = e.clip_content
	t.snap_x  = e.snap_x
	t.snap_y  = e.snap_y
	t.opacity = e.opacity
	t.hit_test_mask = e.hit_test_mask
	t.border_width_left   = e.border_width_left
	t.border_width_right  = e.border_width_right
	t.border_width_top    = e.border_width_top
	t.border_width_bottom = e.border_width_bottom
	t.corner_radius_top_left     = e.corner_radius_top_left
	t.corner_radius_top_right    = e.corner_radius_top_right
	t.corner_radius_bottom_left  = e.corner_radius_bottom_left
	t.corner_radius_bottom_right = e.corner_radius_bottom_right
	t.corner_radius_kappa        = e.corner_radius_kappa
	t.border_color_left   = e.border_color_left
	t.border_color_right  = e.border_color_right
	t.border_color_top    = e.border_color_top
	t.border_color_bottom = e.border_color_bottom
	t.border_dash_count   = e.border_dash_count
	t.border_dash         = list(e, e.border_dash_count, {border_dash=1})
	t.border_dash_offset  = e.border_dash_offset
	t.border_offset = e.border_offset
	t.background_type = e.background_type
	t.background_color = e.background_color_set and e.background_color or nil
	t.background_x1 = e.background_x1
	t.background_y1 = e.background_y1
	t.background_x2 = e.background_x2
	t.background_y2 = e.background_y2
	t.background_r1 = e.background_r1
	t.background_r2 = e.background_r2
	t.background_color_stop_count = e.background_color_stop_count
	t.background_color_stops = list(e, e.background_color_stop_count, {
		background_color_stop_color=1,
		background_color_stop_offset=1,
	})
	--TODO: background_image = e.background_image
	t.background_hittable            = e.background_hittable
	t.background_operator            = e.background_operator
	t.background_clip_border_offset  = e.background_clip_border_offset
	t.background_x                   = e.background_x
	t.background_y                   = e.background_y
	t.background_rotation            = e.background_rotation
	t.background_rotation_cx         = e.background_rotation_cx
	t.background_rotation_cy         = e.background_rotation_cy
	t.background_scale               = e.background_scale
	t.background_scale_cx            = e.background_scale_cx
	t.background_scale_cy            = e.background_scale_cy
	t.background_extend              = e.background_extend
	t.shadow_count = e.shadow_count
	t.shadows = list(e, e.shadow_count, {
		shadow_x       =1,
		shadow_y       =1,
		shadow_color   =1,
		shadow_blur=1,
		shadow_passes=1,
		shadow_inset   =1,
		shadow_content =1,
	})
	t.text_utf8 = utf8_text(e)
	t.text_maxlen = e.text_maxlen
	t.text_dir = e.text_dir
	t.text_align_x = e.text_align_x
	t.text_align_y = e.text_align_y
	t.paragraph_dir     = e.paragraph_dir
	t.line_spacing      = e.line_spacing
	t.hardline_spacing  = e.hardline_spacing
	t.span_count = e.span_count
	t.text_spans = list(e, e.span_count, {
		span_offset            =1,
		span_font_id           =1,
		span_font_size         =1,
		span_features          =cstring,
		span_script            =cstring,
		span_lang              =cstring,
		span_paragraph_dir     =1,
		span_nowrap            =1,
		span_text_color        =1,
		span_text_opacity      =1,
		span_text_operator     =1,
	})
	t.text_selectable   = e.text_selectable
	--TODO:
	-- text_caret_width
	-- text_caret_color
	-- text_caret_insert_mode
	t.in_transition     = e.in_transition
	t.layout_type       = e.layout_type
	t.align_items_x     = e.align_items_x
	t.align_items_y     = e.align_items_y
	t.item_align_x      = e.item_align_x
	t.item_align_y      = e.item_align_y
	t.flex_flow         = e.flex_flow
	t.flex_wrap         = e.flex_wrap
	t.fr                = e.fr
	t.break_before      = e.break_before
	t.break_after       = e.break_after
	t.grid_col_fr_count = e.grid_col_fr_count
	t.grid_row_fr_count = e.grid_row_fr_count
	t.grid_col_fr       = e.grid_col_fr
	t.grid_row_fr       = e.grid_row_fr
	t.grid_col_gap      = e.grid_col_gap
	t.grid_row_gap      = e.grid_row_gap
	t.grid_flow         = e.grid_flow
	t.grid_wrap         = e.grid_wrap
	t.grid_min_lines    = e.grid_min_lines
	t.grid_col          = e.grid_col
	t.grid_row          = e.grid_row
	t.grid_col_span     = e.grid_col_span
	t.grid_row_span     = e.grid_row_span

	--remove values that are the same as the default value.
	for k,v in pairs(t) do
		if type(v) ~= 'table' and v == default_e[k] then
			t[k] = nil
		end
	end

	--serialize children.
	if e.child_count > 0 then
		local dt = {}
		for i = 0, e.child_count-1 do
			dt[i+1] = serialize_layer(e:child(i))
		end
		--remove trailing empty children.
		while #dt > 0 and next(dt[#dt]) == nil do
			pop(dt)
		end
		if #dt > 0 then
			t.children = dt
		end
	end
	return t
end

local function deserialize_layer(e, t)
	for k,v in glue.sortedpairs(t) do
		if k == 'children' then
			e.child_count = #v
			for i,t in ipairs(v) do
				deserialize_layer(e:child(i-1), t)
			end
		elseif k == 'text_utf8' then
			e:set_text_utf8(v, #v)
		elseif type(v) == 'table' then
			for i,t in ipairs(v) do
				for k,v in glue.sortedpairs(t) do
					local set = e['set_'..k]
					set(e, i-1, v)
				end
			end
		else
			e[k] = v
		end
	end
end

local function create_top_e()
	if top_e then
		top_e:free()
	end
	top_e = lib:layer()
	top_e.x = 1100
	top_e.y = 100
	top_e.w = 500
	top_e.h = 300
	top_e.border_width = 1
end

--session management ---------------------------------------------------------

local function session_file(i)
	return string.format('layer_test_state_%d.lua', i)
end

local function state_file()
	return 'layer_test_state.lua'
end

local function save_session()
	if not session_number then return end
	local t = serialize_layer(top_e)
	local file = session_file(session_number)
	save_table(file, {root = t, selected_layer_path = selected_layer_path})
end

local function load_session(sn)
	create_top_e()
	local t = load_table(session_file(sn))
	if t then
		selected_layer_path = t.selected_layer_path
		deserialize_layer(top_e, t.root)
	end
	session_number = sn
end

local function load_sessions()
	sessions = {}
	local i = 1
	while glue.canopen(session_file(i)) do
		sessions[i] = i
		i = i + 1
	end
end

local function load_state()
	local state = load_table(state_file())
	if state then
		load_session(state.session_number)
		testui:continuous_repaint(state.continuous_repaint)
		continuous_repaint = state.continuous_repaint
	else
		create_top_e()
	end
end

local function save_state()
	save_table(state_file(), {
		session_number = session_number,
		continuous_repaint = continuous_repaint,
	})
end

--testui widget wrappers -----------------------------------------------------
--they all use the upvalues `e` and `testui`.

local function get_prop(e, prop) return e[prop] end
local function set_prop(e, prop, v) e[prop] = v; layer_changed = true end
local function get_prop_i(e, prop, i) return e['get_'..prop](e, i) end
local function set_prop_i(e, prop, v, i) e['set_'..prop](e, i, v); layer_changed = true end
local function get_prop_ij(e, prop, i, j) return e['get_'..prop](e, i, j) end
local function set_prop_ij(e, prop, v, i, j) e['set_'..prop](e, i, j, v); layer_changed = true end
local function getset(prop, i, j)
	local id = i and prop..'['..i..']' or prop
	get = j and get_prop_ij or i and get_prop_i or get_prop
	set = j and set_prop_ij or i and set_prop_i or set_prop
	return id, get, set
end
local function slide(prop, min, max, step, ...)
	local id, get, set = getset(prop, ...)
	local v = get(e, prop, ...)
	local v = testui:slide(id, nil, v, min, max, step, get(default_e, prop, 0))
	if v then
		set(e, prop, v, ...)
		return v
	end
end
local function slidex(prop, ...) return slide(prop, -testui.win_w/2, testui.win_w, .5, ...) end
local function slidey(prop, ...) return slide(prop, -testui.win_h/2, testui.win_h, .5, ...) end
local function slidew(prop, ...) return slide(prop, -100, 100, .5, ...) end
local function slidea(prop, ...) return slide(prop, -360, 360, .5, ...) end
local function sliden(prop, ...) return slide(prop, -10, 10, .1, ...) end
local function slideo(prop, ...) return slide(prop, -2, 2, .001, ...) end
local function pickcolor(prop, ...)
	local id, get, set = getset(prop, ...)
	local r, g, b, a = color.parse_rgba32(get(e, prop, ...))
	local h, s, l = color.convert('hsl', 'rgb', r, g, b)

	testui:pushgroup'down'
	testui.margin_h = 0
	testui.min_h = 11
	testui:label(prop)
	testui:popgroup()
	testui:pushgroup('right', 1/4)
	local h1 = testui:slide(id..'_H', 'H', h, 0, 359, 1)
	local s1 = testui:slide(id..'_S', 'S', s, 0, 1, .01)
	local l1 = testui:slide(id..'_L', 'L', l, 0, 1, .01)
	local a1 = testui:slide(id..'_A', 'a', a, 0, 1, .01)
	testui:popgroup()

	if h1 or s1 or l1 or a1 then
		if h1 and l == 0 and s == 0 and a == 0 then l1 = .5; s1 = 1; a1 = 1 end
		local r, g, b = color.convert('rgb', 'hsl', h1 or h, s1 or s, l1 or l)
		local c = color.format('rgba32', 'rgb', r, g, b, a1 or a)
		set(e, prop, c, ...)
		return c
	end
end

local map_t = glue.memoize(function(prop) return {} end)
local function enum_map(prop, prefix, options)
	local t = map_t(prop)
	if not next(t) then
		if type(prefix) == 'string' then
			for i,s in ipairs(options) do
				local enum = layer[prefix:upper()..s:upper()]
				t[s] = enum
				t[enum] = s
			end
		else
			glue.update(t, prefix)
			glue.update(t, glue.index(prefix))
		end
	end
	return t
end
local function choose(prop, prefix, options, ...)
	local id, get, set = getset(prop, ...)
	local t = enum_map(prop, prefix, options)
	local v = t[get(e, prop, ...)]
	testui:pushgroup'down'
	testui.margin_h = -2
	testui:label(prop)
	testui:popgroup()
	testui:pushgroup'right'
	testui.min_w = 0
	local s = testui:choose(id, options, v)
	testui:popgroup()
	if s then
		local v = t[s]
		set(e, prop, v, ...)
		return v
	end
end

local function bits_to_options(bits, maps)
	local vt = {}
	for k,v in pairs(maps) do
		if type(k) == 'number' and glue.getbit(bits, k) then
			vt[v] = true
		end
	end
	return vt
end
local function mchoose(prop, prefix, options, ...)
	local id, get, set = getset(prop, ...)
	local t = enum_map(prop, prefix, options)
	local v = get(e, prop, ...)
	testui:pushgroup'down'
	testui.margin_h = -2
	testui:label(prop)
	testui:popgroup()
	testui:pushgroup'right'
	testui.min_w = 0
	local vt = bits_to_options(v, t)
	local s = testui:choose(id, options, vt)
	if s then
		local v = glue.setbit(v, t[s], not vt[s])
		set(e, prop, v, ...)
	end
	testui:popgroup()
end

local function toggle(prop, ...)
	local id, get, set = getset(prop, ...)
	local v = get(e, prop, ...)
	if testui:button(id, nil, v) then
		set(e, prop, not v, ...)
	end
end

--test UI window -------------------------------------------------------------

function testui:layer_line(id, sel_child_i)
	self.min_w = 0
	self.min_w = 100
	local n = testui:slide(id, 'child_count', e.child_count, -1, 10, 1)
	if n then
		local i = e.child_count
		e.child_count = n
		for i = i,n-1 do
			local e = e:child(i)
			e.border_width = 1
		end
	end
	local t = {}
	for i = 0, e.child_count-1 do
		push(t, i)
	end
	self.min_w = 0
	self.min_w = 0
	return self:choose(id..'_children', t, sel_child_i, 'child %d')
end

function testui:repaint()

	self:pushgroup'down'
	self.min_w = 240
	self.max_w = 240

	--session selector --------------------------------------------------------

	local y = self.y
	self:pushgroup'right'
	self.x = self.win_w - 80 * #sessions - 20 - 30 * 2 - 80
	self.min_w = 80
	local sn = self:choose('session', sessions, session_number, 'session %d')
	if sn then
		save_session()
		load_session(sn)
	end
	self.min_w = 30
	if self:button'+' then
		push(sessions, #sessions + 1)
	end
	if self:button'-' then
		os.remove(session_file(pop(sessions)))
	end

	self.x = self.x + 20
	if self:button('CRP', nil, continuous_repaint) then
		continuous_repaint = not continuous_repaint
		testui:continuous_repaint(continuous_repaint)
	end

	self:popgroup()
	self.y = y

	--layer tree editor / layer selector --------------------------------------

	local e0 = e

	e = top_e
	local path_i = 1
	local id = ''
	while true do
		self:pushgroup'right'
		local child_i = selected_layer_path[path_i]
		local sel_child_i = self:layer_line(id, child_i)
		local toggled = child_i and sel_child_i == child_i
		child_i = sel_child_i or child_i
		self:popgroup()
		if toggled or (child_i or 0) >= e.child_count then
			--clear selections of children including this level.
			for i = #selected_layer_path, path_i, -1 do
				selected_layer_path[i] = nil
			end
			break
		end
		if not child_i then
			break
		end
		selected_layer_path[path_i] = child_i
		e = e:child(child_i)
		if sel_child_i then --clear selections of children beyond this level.
			for i = #selected_layer_path, path_i+1, -1 do
				selected_layer_path[i] = nil
			end
		end
		path_i = path_i + 1
		id = id..'/'..child_i
	end

	if e0 then e0.background_color_set = false end
	if e then e.background_color = 0xffffff11 end

	--layer property editors --------------------------------------------------

	self:pushgroup'right'

	self:pushgroup'down'

	self:heading'Position'

	if sliden('index') then
		selected_layer_path[#selected_layer_path] = e.index
	end
	self:pushgroup('right', 1/2)
	slidex('x')
	slidey('y')
	self:nextgroup()
	slidex('w')
	slidey('h')
	self:popgroup()

	self:heading'Drawing'

	choose('operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'})

	self:pushgroup('right', 1/3)
	toggle'clip_content'
	toggle'snap_x'
	toggle'snap_y'
	self:popgroup()

	slideo'opacity'

	self:heading'Border'

	slidew('border_width'       )
	self:pushgroup('right', 1/2)
	slidew('border_width_left'  )
	slidew('border_width_right' )
	self:nextgroup()
	slidew('border_width_top'   )
	slidew('border_width_bottom')
	self:popgroup()

	slidew('corner_radius')
	self:pushgroup('right', 1/2)
	slidew('corner_radius_top_left')
	slidew('corner_radius_top_right')
	self:nextgroup()
	slidew('corner_radius_bottom_left')
	slidew('corner_radius_bottom_right')
	self:popgroup()

	pickcolor('border_color')
	pickcolor('border_color_left')
	pickcolor('border_color_right')
	pickcolor('border_color_top')
	pickcolor('border_color_bottom')

	slideo('border_offset')

	sliden('border_dash_count')
	for i = 0, e.border_dash_count-1 do
		slide('border_dash', -100, 100, .1, i)
	end
	slide('border_dash_offset', -100, 100, .1)

	self:heading'Padding'

	slidew('padding'       )
	self:pushgroup('right', 1/2)
	slidew('padding_left'  )
	slidew('padding_right' )
	self:nextgroup()
	slidew('padding_top'   )
	slidew('padding_bottom')
	self:popgroup()

	self:heading'Transforms'

	slidea('rotation')
	self:pushgroup('right', 1/2)
	slidex('rotation_cx')
	slidey('rotation_cy')
	self:popgroup()

	slideo('scale')
	self:pushgroup('right', 1/2)
	slidex('scale_cx')
	slidey('scale_cy')
	self:popgroup()

	self:heading'Shadows'

	slide('shadow_count', -10, 10, 1)
	for i = 0, e.shadow_count-1 do
		pickcolor('shadow_color', i)
		self:pushgroup('right', 1/2)
		slidew('shadow_x', i)
		slidew('shadow_y', i)
		self:popgroup()
		self:pushgroup('right', 1/2)
		slide ('shadow_blur',   -300, 300, 1, i)
		slide ('shadow_passes',  -20,  20, 1, i)
		self:nextgroup()
		toggle('shadow_inset', i)
		toggle('shadow_content', i)
		self:popgroup()
	end

	self:nextgroup(10)

	self:heading'Background'

	choose('background_type', 'background_', {'color', 'linear_gradient', 'radial_gradient', 'image'})
	pickcolor('background_color')
	toggle('background_color_set')

	self:pushgroup('right', 1/2)
	slidex('background_x1')
	slidey('background_y1')
	self:nextgroup()
	slidex('background_x2')
	slidey('background_y2')
	self:nextgroup()
	slidex('background_r1')
	slidey('background_r2')
	self:popgroup()

	sliden('background_color_stop_count')

	for i = 0, e.background_color_stop_count-1 do
		pickcolor('background_color_stop_color', i)
		slideo('background_color_stop_offset', i)
	end

	--[[
		set_background_image=1,
		get_background_image_w=1,
		get_background_image_h=1,
		get_background_image_stride=1,
		get_background_image_pixels=1,
		get_background_image_format=1,
		background_image_invalidate=1,
		background_image_invalidate_rect=1,
	]]

	toggle('background_hittable')
	choose('background_operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'})
	slideo('background_clip_border_offset')

	self:pushgroup('right', 1/2)
	slidex('background_x')
	slidex('background_y')
	self:popgroup()
	slidea('background_rotation')
	self:pushgroup('right', 1/2)
	slidex('background_rotation_cx')
	slidey('background_rotation_cy')
	self:popgroup()
	slideo('background_scale')
	self:pushgroup('right', 1/2)
	slidex('background_scale_cx')
	slidey('background_scale_cy')
	self:popgroup()

	choose('background_extend', 'background_extend_', {'none', 'pad', 'reflect', 'repeat'})

	self:heading'Text'

	self:pushgroup'right'
	self.min_w = 0
	local text = utf8_text(e)
	local text_name = test_text_names[text]
	local sel_text_name = self:choose('text_utf8', glue.keys(test_texts, true), text_name)
	if sel_text_name then
		local sel_text = test_texts[sel_text_name]
		e:set_text_utf8(sel_text, #sel_text)
		layer_changed = true
	end
	self:popgroup()

	slide ('text_maxlen', -10, 9999, 1)
	choose('text_dir', 'dir_', {'auto', 'ltr', 'rtl', 'wltr', 'wrtl'})
	choose('text_align_x', 'align_', {'left', 'right', 'center', 'justify', 'start', 'end'})
	choose('text_align_y', 'align_', {'top', 'bottom', 'center'})
	slideo('line_spacing')
	slideo('hardline_spacing')
	slideo('paragraph_spacing')

	self:heading'Text Spans'

	sliden('span_count')
	for i = 0, e.span_count-1 do
		choose('span_font_id', {OpenSans=0, Amiri=1}, {'OpenSans', 'Amiri'}, i)
		slide ('span_font_size', -10, 100, 1, i)
		--TODO: slide ('features',
		--TODO: choose('script', i)
		--TODO: choose('lang'             , i)
		choose('span_paragraph_dir', 'dir_', {'auto', 'ltr', 'rtl', 'wltr', 'wrtl'}, i)
		toggle('span_nowrap'          , i)
		pickcolor('span_text_color'   , i)
		slideo('span_text_opacity'    , i)
		choose('span_text_operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'}, i)
	end

	self:heading'Text Cursor & Selection'

	toggle'text_selectable'
	slide('cursor_offset', -1, e.text_len + 1, 1)

	self:nextgroup(10)

	self:heading'Layouting'

	self.x = self.x + 40
	choose('layout_type', 'layout_', {'null', 'textbox', 'flexbox', 'grid'})
	self.x = self.x - 40

	self:pushgroup('right', 1/2)
	slidex('min_cw')
	slidey('min_ch')
	self:popgroup()

	toggle('in_transition')

	self:heading'Flex & Grid Layout'

	choose('align_items_x', 'align_', {
		'left', 'right', 'center', 'stretch', 'start', 'end',
		'space_evenly', 'space_around', 'space_between',
	})
	choose('align_items_y', 'align_', {
		'top', 'bottom', 'center', 'stretch', 'start', 'end',
		'space_evenly', 'space_around', 'space_between',
	})
	choose('item_align_x', 'align_', {
		'left', 'right', 'center', 'stretch', 'start', 'end',
	})
	choose('item_align_y', 'align_', {
		'top', 'bottom', 'center', 'stretch', 'start', 'end',
		'baseline',
	})

	self:heading'Child / Flex & Grid Layout'

	slideo('fr')

	choose('align_x', 'align_', {
		'default',
		'left', 'right', 'center', 'stretch', 'start', 'end',
	})
	choose('align_y', 'align_', {
		'default',
		'top', 'bottom', 'center', 'stretch', 'start', 'end',
	})

	self:heading'Flex Layout'

	choose('flex_flow', 'flex_flow_', {'x', 'y'})

	toggle('flex_wrap')

	self:heading'Child / Flex Layout'

	self:pushgroup('right', 1/2)
	toggle('break_before')
	toggle('break_after')
	self:popgroup()

	self:heading'Grid Layout'

	mchoose('grid_flow', 'grid_flow_', {'y', 'r', 'b'})

	sliden('grid_col_fr_count')
	for i = 0, e.grid_col_fr_count-1 do
		slideo('grid_col_fr', i)
	end
	sliden('grid_row_fr_count')
	for i = 0, e.grid_row_fr_count-1 do
		slideo('grid_row_fr', i)
	end

	self:pushgroup('right', 1/2)
	slidew('grid_col_gap')
	slidew('grid_row_gap')
	self:popgroup()

	sliden('grid_wrap')

	sliden('grid_min_lines')

	self:heading'Child / Grid Layout'

	self:pushgroup('right', 1/2)
	sliden('grid_col')
	sliden('grid_col_span')
	self:nextgroup()
	sliden('grid_row')
	sliden('grid_row_span')
	self:popgroup()

	self:popgroup()
	self:popgroup()
	self:popgroup()

	--sync'ing, drawing and hit-testing ---------------------------------------

	local repaint

	if not self.ewindow then

		local d = self.app:active_display()
		self.ewindow = self.app:window{
			x = d.cw - 1000,
			y = 100,
			w = 1000,
			h = d.ch - 100,
			parent = self.window,
		}

		function self.ewindow:repaint()
			local cr = self:bitmap():cairo()
			local repaint_t0 = time.clock()
			cr:operator'source'
			cr:rgba(0, 0, 0, 0)
			cr:paint()
			cr:operator'over'
			local draw_t0 = time.clock()
			top_e:draw(cr)
			local draw_t = time.clock()
			local repaint_t = draw_t
			local draw_dt    = draw_t    - draw_t0
			local repaint_dt = repaint_t - repaint_t0

			if layer_changed then
				draw_changed_dt = draw_dt
				draw_changed = false
			end

			if draw_t - (draw_fps_t or 0) > 0.5 then
				draw_fps_t  = t
				draw_fps_dt = draw_dt
			end
			if draw_t - (repaint_fps_t or 0) > 0.5 then
				repaint_fps_t = t
				repaint_fps_dt = repaint_dt
			end
		end

		function self.ewindow:keyup(key)
			if key == 'esc' then
				self:parent():close()
			end
		end

		--hit-testing

		local lbuf = ffi.new'layer_t*[1]'
		function self.ewindow:mousemove(mx, my)
			local cr = self:bitmap():cairo()
			hit_area = top_e:hit_test(cr, mx, my, 0, lbuf)
			hit_e = lbuf[0]
			if hit_e == nil then hit_e = nil end
			if hit_area == 0 then hit_area = nil end
		end

		function self.ewindow:mousedown(button)
			if hit_e and button == 'left' then
				selected_layer_path = {}
				local e = hit_e
				while e ~= top_e do
					table.insert(selected_layer_path, 1, e.index)
					e = e.parent
				end
			end
		end

	end

	if top_e:sync() then
		self.ewindow:invalidate()
	end

	self.x = self.win_w - 1200
	self.y = 10
	self:heading(string.format(
		'Draw layers:                              %.1f fps, %.1f ms',
		1 / draw_fps_dt, draw_fps_dt * 1000))
	self:heading(string.format(
		'Draw layers after change:     %.1f fps, %.1f ms',
		1 / draw_changed_dt, draw_changed_dt * 1000))
	self:heading(string.format(
		'Repaint:                                      %.1f fps, %.1f ms',
		1 / repaint_fps_dt, repaint_fps_dt * 1000))

end

load_sessions()
load_state()
testui:run()
save_session()
save_state()

--free everything and check for leaks.
top_e:release()
default_e:release()
lib:release()
layer.memreport()

