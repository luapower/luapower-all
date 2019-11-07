
local ffi = require'ffi'
local time = require'time'
local fs = require'fs'
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

local font_dir = 'media/fonts'
local fonts = {}
for _,s in ipairs{
	'OpenSans-Regular.ttf',
	'Amiri-Regular.ttf',
	'NotoNaskhArabic-Regular.ttf',
	'SourceHanSans.ttc',
	'SourceHanSerif.ttc',
	'ionicons.ttf',
	'Font Awesome 5 Free-Solid-900.otf',
	'NotoColorEmoji.ttf',
	'Sacramento-Regular.ttf',
	'Tangerine-Regular.ttf',
} do if glue.canopen(font_dir..'/'..s) then
	table.insert(fonts, s)
end end

local font_ids = glue.index(fonts)

local font_names = {}
for i,s in ipairs(fonts) do
	s = s:match'([^/]+)%....$'
	font_names[i] = s:sub(1, 5)..s:sub(-1)
end
local font_map = glue.update({}, font_names, glue.index(font_names))

local function load_font(font_id, file_data_buf, file_size_buf, mmapped_buf)
	local font_name = assert(fonts[font_id])
	local font_data = assert(bundle.load(font_dir..'/'..font_name))
	local buf = glue.malloc('char', #font_data)
	ffi.gc(buf, nil)
	ffi.copy(buf, font_data, #font_data)
	file_data_buf[0] = buf
	file_size_buf[0] = #font_data
	mmapped_buf[0] = false
end

local function unload_font(font_id, file_data, file_size)
	glue.free(file_data)
end

assert(layer.memtotal() == 0)

local lib = layer.layerlib(load_font, unload_font)
lib.mem_font_cache_max_size = 1/0

local default_e = lib:layer()

local lorem_ipsum = bundle.load('lorem_ipsum.txt')
local test_texts = {
	[''] = '',
	dia = 's\u{0320}a\u{0300}',
	ipsum = lorem_ipsum,
	ffi = 'aaa ffi bbb',
	ar = 'السَّلَامُ عَلَيْكُمْ‎',
	ch = '这是一些中文文本',
	par = u'Hey\nYou&ps;New Paragraph',
	embed = u'a\u{100000}\u{100001}b',
	ico = '\xF0\x9F\x98\x81'
}
local test_text_names = glue.index(test_texts)

--global state ---------------------------------------------------------------

local top_e, sel_e
local selected_layer_path = {}
local e, hit_e, hit_area

local sessions = {}
local session = '1'
local tab = 'Position'
local layer_changed = false
local draw_changed_dt = 0
local draw_fps_t, draw_fps_dt = 0, 0
local repaint_fps_t, repaint_fps_dt = 0, 0

sel_e = lib:layer()
--sel_e.background_color = 0xffffff22
sel_e.border_width = 2
sel_e:set_border_dash(0, 10)
sel_e.border_offset = 1

--layer tree (de)serialization -----------------------------------------------

local function serialize_layer(e)

	--serialize a list of sub-objects (shadows, text spans, etc.)
	local function list(e, n, fields)
		if n == 0 then return end
		local dt = {}
		for i = 0, n-1 do
			local t = {}
			for k, get in glue.sortedpairs(fields) do
				get = type(get) == 'function' and get or e['get_'..k]
				local v = get(e, i)
				local v0 = get(default_e, 0)
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
	t.background_color = e.background_color
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
	t.background_opacity             = e.background_opacity
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
	t.text = e.text
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
		span_font              =function(e, i)
			return fonts[e:get_span_font_id(i)]
		end,
		span_font_face_index   =1,
		span_font_size         =1,
		span_features          =1,
		span_script            =1,
		span_lang              =1,
		span_paragraph_dir     =1,
		span_wrap              =1,
		span_text_color        =1,
		span_text_opacity      =1,
		span_text_operator     =1,
		span_underline         =1,
		span_underline_color   =1,
		span_underline_opacity =1,
		span_baseline          =1,
	})
	t.text_cursor_count = e.text_cursor_count
	t.text_cursors      = list(e, e.text_cursor_count, {
		text_cursor_offset     =1,
		text_cursor_which      =1,
		text_cursor_sel_offset =1,
		text_cursor_sel_which  =1,
		text_cursor_x          =1,
		text_insert_mode       =1,
		text_caret_opacity     =1,
		text_caret_thickness   =1,
		text_selection_color   =1,
		text_selection_opacity =1,
	})
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
		elseif type(v) == 'table' then
			local kk = k
			for i,t in ipairs(v) do
				for k,v in glue.sortedpairs(t) do
					if k == 'span_font' then
						k = 'span_font_id'
						v = font_ids[v] or -1
					end
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
end

local function init_top_e()
	top_e.x = 100
	top_e.y = 100
	top_e.w = 500
	top_e.h = 300
	top_e.border_width = 1
end

--session management ---------------------------------------------------------

local function session_file(sn)
	return string.format('layer_test/layer_test_state_%s.lua', sn)
end

local function state_file()
	return 'layer_test/layer_test_state.lua'
end

local function session_list()
	local t = {}
	for s,d in fs.dir'layer_test' do
		if s then
			local sn = d:is'file' and s:match'^layer_test_state_(.-)%.lua'
			if sn then
				push(t, sn)
			end
		end
	end
	table.sort(t)
	if #t == 0 then t[1] = '1' end
	return t
end

local function save_session()
	local t = serialize_layer(top_e)
	local file = session_file(session)
	save_table(file, {
		root = t,
		selected_layer_path = selected_layer_path,
		tab = tab,
	})
end

local function load_session(name)
	create_top_e()
	local t = load_table(session_file(name))
	if t then
		selected_layer_path = t.selected_layer_path
		tab = t.tab
		deserialize_layer(top_e, t.root)
	else
		init_top_e()
	end
	session = name
end

local function load_sessions()
	sessions = session_list()
end

local function load_state()
	local state = load_table(state_file())
	local sn = state and state.session or '1'
	load_session(glue.indexof(sn, sessions) and sn or '1')
end

local function save_state()
	save_table(state_file(), {
		session = session,
	})
end

--testui widget wrappers -----------------------------------------------------
--they all use the upvalues `e` and `testui`.

local function get_prop(e, prop) return e[prop] end
local function set_prop(e, prop, v) e[prop] = v; layer_changed = true end
local function get_prop_i(e, prop, i) return e['get_'..prop](e, i) end
local function set_prop_i(e, prop, v, i) e['set_'..prop](e, i, v); layer_changed = true end
local function get_prop_if(e, prop, _, is_set)
	if not e[is_set](e) then return nil end
	return e[prop]
end
local function get_prop_if_i(e, prop, i, is_set)
	if not e[is_set](e, i) then return nil end
	return e['get_'..prop](e, i)
end
local function getset(prop, i, is_set)
	local id = i and prop..'['..i..']' or prop
	get = is_set ~= nil and (i ~= nil and get_prop_if_i or get_prop_if) or i and get_prop_i or get_prop
	set = i and set_prop_i or set_prop
	return id, get, set
end
local function slide(prop, min, max, step, ...)
	local id, get, set = getset(prop, ...)
	local v = get(e, prop, ...)
	local _, get_default = getset(prop, (...))
	local default_v = get_default(default_e, prop, 0)
	local v = testui:slide(id, nil, v, min, max, step, default_v)
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
	local r, g, b, a = color.parse_rgba32(get(e, prop, ...) or 0)
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
		if type(prefix) == 'string' then --enum mapping
			for i,s in ipairs(options) do
				local enum = layer[prefix:upper()..s:upper()]
				t[s] = enum
				t[enum] = s
			end
		elseif prefix then --user-specified mapping
			glue.update(t, prefix)
			glue.update(t, glue.index(prefix))
		else --null mapping
			for i,v in ipairs(options) do
				t[v] = v
			end
		end
	end
	return t
end
local function choose(prop, prefix, options, ...)
	local id, get, set = getset(prop, ...)
	local v = get(e, prop, ...)
	local t = enum_map(prop, prefix, options)
	local v = t[v]
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

local function parent_map(e)
	void = ffi.cast('layer_t*', nil)
	local m = {[void] = 'nil', ['nil'] = void}
	local n = {'nil'}
	local i = 2
	while e ~= nil do
		local s = 'parent '..i
		m[e.parent] = s
		m[s] = e.parent
		n[i] = s
		i = i + 1
		e = e.parent
	end
	return m, n
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
	self.x = self.win_w - 40 * #sessions - 20 - 30 * 2
	self.min_w = 40
	local sn = self:choose('session', sessions, session)
	if sn then
		save_session()
		load_session(sn)
	end
	self.min_w = 30
	if self:button'+' then
		push(sessions, tostring(#sessions + 1))
	end
	if self:button'-' then
		local i = glue.indexof(session, sessions)
		os.remove(session_file(table.remove(sessions, i)))
		if #sessions == 0 then sessions[1] = '1' end
		load_session(sessions[math.min(i, #sessions)] or '1')
	end

	self:popgroup()
	self.y = y

	--layer tree editor / layer selector --------------------------------------

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

	if sel_e then
		sel_e.pos_parent = e.parent
		sel_e.x = e.x
		sel_e.y = e.y
		sel_e.w = e.w
		sel_e.h = e.h
		sel_e.rotation = e.rotation
		sel_e.rotation_cx = e.rotation_cx
		sel_e.rotation_cy = e.rotation_cy
		sel_e.scale    = e.scale
		sel_e.scale_cx = e.scale_cx
		sel_e.scale_cy = e.scale_cy
	end

	--layer property editors --------------------------------------------------

	self:pushgroup('right')

	self.min_w = 80

	tab = self:choose('tab', {
		'Position', 'Border & Padding', 'Background', 'Shadows', 'Text', 'Layout',
	}, tab) or tab

	self:popgroup()

	self:pushgroup'right'

	self:pushgroup'down'

	if tab == 'Position' then

		self:heading'Z-Index'

		if sliden('index') then
			selected_layer_path[#selected_layer_path] = e.index
		end

		self:heading'Position & Size'

		self:pushgroup('right', 1/2)
		slidex('x')
		slidey('y')
		self:nextgroup()
		slidex('w')
		slidey('h')
		self:popgroup()

		local parent_map, parent_names = parent_map(e)
		choose('pos_parent', parent_map, parent_names)

		self:heading'Drawing'

		choose('operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'})

		self:pushgroup('right', 1/2)
		toggle'visible'
		toggle'clip_content'
		self:nextgroup()
		toggle'snap_x'
		toggle'snap_y'
		self:popgroup()

		slideo'opacity'

		self:heading'Transform'

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

	elseif tab == 'Border & Padding' then

		self:heading'Border Width'

		slidew('border_width'       )
		self:pushgroup('right', 1/2)
		slidew('border_width_left'  )
		slidew('border_width_right' )
		self:nextgroup()
		slidew('border_width_top'   )
		slidew('border_width_bottom')
		self:popgroup()

		self:heading'Border Offset'

		slideo('border_offset')

		self:heading'Corner Radius'

		slidew('corner_radius')
		self:pushgroup('right', 1/2)
		slidew('corner_radius_top_left')
		slidew('corner_radius_top_right')
		self:nextgroup()
		slidew('corner_radius_bottom_left')
		slidew('corner_radius_bottom_right')
		self:popgroup()

		self:heading'Border Color'

		pickcolor('border_color')
		pickcolor('border_color_left')
		pickcolor('border_color_right')
		pickcolor('border_color_top')
		pickcolor('border_color_bottom')

		self:heading'Border Dash'

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

	elseif tab == 'Background' then

		self:heading'Background'

		choose('background_type', 'background_type_', {'none', 'color', 'linear_gradient', 'radial_gradient', 'image'})

		toggle('background_hittable')
		choose('background_operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'})
		slideo'background_opacity'
		slideo('background_clip_border_offset')

		if e.background_type == layer.BACKGROUND_TYPE_COLOR then

			self:heading'Background Color'

			pickcolor('background_color')

		elseif
			   e.background_type == layer.BACKGROUND_TYPE_LINEAR_GRADIENT
			or e.background_type == layer.BACKGROUND_TYPE_RADIAL_GRADIENT
		then

			self:heading'Background Gradient'

			self:pushgroup('right', 1/2)
			slidex('background_x1')
			slidey('background_y1')
			self:nextgroup()
			slidex('background_x2')
			slidey('background_y2')
			if e.background_type == layer.BACKGROUND_TYPE_RADIAL_GRADIENT then
				self:nextgroup()
				slidex('background_r1')
				slidey('background_r2')
			end
			self:popgroup()

			sliden('background_color_stop_count')

			for i = 0, e.background_color_stop_count-1 do
				pickcolor('background_color_stop_color', i)
				slideo('background_color_stop_offset', i)
			end

		elseif e.background_type == layer.BACKGROUND_TYPE_IMAGE then

			self:heading'Background Image'

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

		end

		self:heading'Background Extend'

		choose('background_extend', 'background_extend_', {'none', 'pad', 'reflect', 'repeat'})

		self:heading'Background Transforms'

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

	elseif tab == 'Shadows' then

		self:heading'Shadows'

		slide('shadow_count', -10, 10, 1)
		for i = 0, e.shadow_count-1 do
			self:heading('Shadow '..i)
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

	elseif tab == 'Text' then

		self:heading'Text'

		self:pushgroup'right'
		self.min_w = 0
		local text = e.text
		local text_name = test_text_names[text]
		local sel_text_name = self:choose('text', glue.keys(test_texts, true), text_name)
		if sel_text_name then
			local sel_text = test_texts[sel_text_name]
			e.text = sel_text
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

		self:heading'Text Cursors'
		slide('text_cursor_count', -10, 10, 1)
		for i = 0, e.text_cursor_count-1 do
			self:heading('Cursor '..i)

			slide('text_cursor_offset', -1, e.text_utf32_len + 1, 1, i)
			slide('text_cursor_which', -1, 2, 1, i)
			slide('text_cursor_sel_offset', -1, e.text_utf32_len + 1, 1, i)
			slide('text_cursor_sel_which', -1, 2, 1, i)

			toggle('text_insert_mode', i)
			slideo('text_caret_opacity', i)
			slideo('text_caret_thickness', i)
			pickcolor('text_selection_color', i)
			slideo('text_selection_opacity', i)

			if e.text_valid then
				self:heading('Selected Text '..i..' ('..e:get_selected_text_utf32_len(i)..' codepoints)')
				choose('selected_text_font_id', font_map, font_names, i, 'selected_text_has_font_id')
				slide ('selected_text_font_size', -10, 100, 1, i, 'selected_text_has_font_size')
				slide ('selected_text_font_face_index', -1,
					lib:font_face_num(e:get_span_font_id(i)), 1, i, 'selected_text_has_font_face_index')
				----TODO: slide ('features',
				----TODO: choose('script', i)
				----TODO: choose('lang'             , i)
				choose('selected_text_paragraph_dir', 'dir_',
					{'auto', 'ltr', 'rtl', 'wltr', 'wrtl'}, i, 'selected_text_has_paragraph_dir')
				choose('selected_text_wrap'    , 'wrap_', {'word', 'char', 'none'}, i, 'selected_text_has_wrap')
				pickcolor('selected_text_color', i, 'selected_text_has_color')
				slideo('selected_text_opacity' , i, 'selected_text_has_opacity')
				choose('selected_text_operator', 'operator_',
					{'clear', 'source', 'over', 'in', 'out', 'xor'}, i, 'selected_text_has_operator')
				choose('selected_text_underline', 'underline_',
					{'none', 'solid', 'zigzag'}, i, 'selected_text_has_underline')
				pickcolor('selected_text_underline_color', i, 'selected_text_has_underline_color')
				slideo('selected_text_underline_opacity' , i, 'selected_text_has_underline_opacity')
				slideo('selected_text_baseline' , i, 'selected_text_has_baseline')
			else
				self:heading'SPANS ARE INVALID'
			end
		end

		self:nextgroup()

		self:heading'Text Spans'

		sliden('span_count')
		for i = 0, e.span_count-1 do

			--self:pushgroup('right', 1/2)
			self:heading('Span '..i)
			slide ('span_offset', -1, 100, 1, i)
			--self:popgroup()

			choose('span_font_id', font_map, font_names, i)
			slide ('span_font_face_index', -1, lib:font_face_num(e:get_span_font_id(i)), 1, i)
			slide ('span_font_size', -10, 100, 1, i)
			--TODO: slide ('features',
			--TODO: choose('span_script', nil, {'Zyyy', 'Latn', 'Arab'}, i)
			choose('span_lang', nil, {'', 'en-us', 'ar-sa', 'trk'}, i)
			choose('span_paragraph_dir', 'dir_', {'auto', 'ltr', 'rtl', 'wltr', 'wrtl'}, i)
			choose('span_wrap'            , 'wrap_', {'word', 'char', 'none'}, i)
			pickcolor('span_text_color'   , i)
			slideo('span_text_opacity'    , i)
			choose('span_text_operator', 'operator_', {'clear', 'source', 'over', 'in', 'out', 'xor'}, i)
			choose('span_underline'    , 'underline_', {'none', 'solid', 'zigzag'}, i)
			pickcolor('span_underline_color' , i)
			slideo('span_underline_opacity'  , i)
			slideo('span_baseline'           , i)
		end

	elseif tab == 'Layout' then

		self:heading'Layout'

		choose('layout_type', 'layout_type_', {'null', 'textbox', 'flexbox', 'grid'})

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

	ewindow:checkvalid()

end

function testui:keypress(key)
	if self.app:key'ctrl' and tonumber(key) then
		--TODO: change demo
	end
end

--layer window ---------------------------------------------------------------

testui:init()
local app = testui.app
local testui_win = testui.window
local d = app:active_display()

ewindow = app:window{
	x = d.cw - 1000,
	y = 100,
	w = 1000,
	h = d.ch - 100,
	parent = testui_win,
}

function ewindow:checkvalid(update_testui)
	if not top_e.pixels_valid then self:invalidate() end
	if sel_e and not sel_e.pixels_valid then self:invalidate() end
	if update_testui then
		testui_win:invalidate()
	end
end

function ewindow:repaint()
	local cr = self:bitmap():cairo()
	local repaint_t0 = time.clock()
	cr:identity_matrix()
	cr:operator'source'
	cr:rgba(0, 0, 0, 0)
	cr:paint()
	cr:operator'over'
	local draw_t0 = time.clock()
	top_e:draw(cr)
	assert(top_e.pixels_valid)
	local draw_t = time.clock()
	if sel_e then
		sel_e:draw(cr)
		assert(sel_e.pixels_valid)
	end
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

function ewindow:keypress(key)
	local shift = self.app:key'shift'
	local ctrl = self.app:key'ctrl'
	if key == 'right' or key == 'left' then
		assert(e ~= nil)
		e:text_cursor_move_near(0,
			key == 'right' and layer.CURSOR_DIR_NEXT or layer.CURSOR_DIR_PREV,
			ctrl and layer.CURSOR_MODE_WORD or layer.CURSOR_MODE_CHAR,
			0,
			shift)
	elseif key == 'up' or key == 'down' then
		assert(e ~= nil)
		e:text_cursor_move_near_line(0, key == 'up' and -1 or 1, 0/0, shift)
	elseif key == 'pageup' or key == 'pagedown' then
		assert(e ~= nil)
		e:text_cursor_move_near_page(0, key == 'pageup' and -1 or 1, 0/0, shift)
	elseif key == 'home' or key == 'end' then
		assert(e ~= nil)
		e:text_cursor_move_near_page(0, key == 'home' and -1/0 or 1/0, 0/0, shift)
	elseif key == 'backspace' or key == 'delete' then
		if e:get_selected_text_utf32_len(0) == 0 then
			e:text_cursor_move_near(0,
				key == 'backspace'
					and layer.CURSOR_DIR_PREV
					 or layer.CURSOR_DIR_NEXT,
				layer.CURSOR_MODE_CHAR, 0, true)
		end
		e:remove_selected_text(0)
	elseif key == 'insert' then
		e:set_text_insert_mode(0, not e:get_text_insert_mode(0))
	elseif ctrl and key == 'V' then
		local s = self.app:getclipboard'text'
		if s then
			e:insert_text_at_cursor(0, s)
		end
	elseif ctrl and (key == 'C' or key == 'X') then
		self.app:setclipboard(e:get_selected_text(0))
		if key == 'X' then
			e:remove_selected_text(0)
		end
	end
	self:checkvalid(true)
end

function ewindow:keychar(c)
	if c:byte(1, 1) > 31 or c:find'[\n\r\t]' then
		e:insert_text_at_cursor(0, c)
		self:checkvalid(true)
	end
end

function ewindow:keyup(key)
	if key == 'esc' then
		self:parent():close()
	end
end

--hit-testing

local active_e, active_area

function ewindow:mousemove(mx, my)
	local cr = self:bitmap():cairo()
	if active_e then
		if active_area == layer.HIT_TEXT and hit_e.text_cursor_count > 0 then
			local x, y = active_e:from_window(mx, my)
			active_e:text_cursor_move_to_point(0, x, y, true)
		end
	elseif top_e:hit_test(cr, mx, my, 0) then
		hit_e = top_e.hit_test_layer
		hit_area = top_e.hit_test_area
	else
		hit_e, hit_area = nil
	end
	self:checkvalid()
end

function ewindow:mousedown(button)
	if hit_e and button == 'left' then
		selected_layer_path = {}
		local e = hit_e
		while e ~= top_e do
			table.insert(selected_layer_path, 1, e.index)
			e = e.parent
		end
		if hit_area == layer.HIT_TEXT and hit_e.text_cursor_count > 0 then
			hit_e:text_cursor_move_to_point(0, top_e.hit_test_x, top_e.hit_test_y, false)
		end
		active_e, active_area = hit_e, hit_area
	end
	self:checkvalid(true)
end

function ewindow:mouseup(button)
	if hit_e and button == 'left' then
		active_e, active_area = nil
		self:checkvalid(true)
	end
end

--main -----------------------------------------------------------------------

load_sessions()
load_state()
testui:run()
save_session()
save_state()

--free everything and check for leaks.
top_e:release()
if sel_e then sel_e:release() end
default_e:release()

local function pfn(...) return print(string.format(...)) end
pfn('Glyph cache size     : %7.2fmB', lib.glyph_cache_size / 1024.0 / 1024.0)
pfn('Glyph cache count    : %7.0f',   lib.glyph_cache_count)
pfn('GlyphRun cache size  : %7.2fmB', lib.glyph_run_cache_size / 1024.0 / 1024.0)
pfn('GlyphRun cache count : %7.0f',   lib.glyph_run_cache_count)
pfn('Mem Font cache size  : %7.2fmB', lib.mem_font_cache_size / 1024.0 / 1024.0)
pfn('Mem Font cache count : %7.0f',   lib.mem_font_cache_count)
pfn('MMap Font cache count: %7.0f',   lib.mmapped_font_cache_count)

lib:release()
layer.memreport()

